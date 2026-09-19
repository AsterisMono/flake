{
  inputs,
  ...
}:
{
  flake-file.inputs = {
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  flake.modules.aspects.agents.imports = with inputs.self.modules.aspects; [
    herdr
    skills
  ];

  # NixOS provisions the token so the unprivileged Home Manager consumer reads
  # it from a file instead of holding a decryption key of its own.
  flake.modules.nixos.agents =
    { config, ... }:
    {
      nix.settings = {
        extra-substituters = [ "https://cache.numtide.com" ];
        trusted-public-keys = [
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
      };

      sops.secrets.deepseek_api_key = {
        format = "yaml";
        key = "deepseek_api_key";
        sopsFile = config.constants.resources.getSecretPath "deepseek.yaml";
        path = config.constants.resources.userSecretPaths.deepseek_api_key;
        owner = config.constants.nvirellia.username;
        group = config.users.users.${config.constants.nvirellia.username}.group;
        mode = "0400";
      };
    };

  flake.modules.homeManager.agents =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      cshHome = "${config.home.homeDirectory}/.local/share/csh";
      cshConfigFile = "${cshHome}/config.toml";
      cshConfigDeployed = "${cshHome}/.config.toml.deployed";
      cshConfig = (pkgs.formats.toml { }).generate "csh-config.toml" {
        model = "deepseek-flash";
        model_provider = "deepseek";
        forced_login_method = "api";
        model_reasoning_effort = "high";
        web_search = "disabled";
        model_catalog_json = "${cshHome}/models.json";
        non_prefixed_mcp_tool_servers = [ "web" ];
        mcp_servers.web = {
          command = lib.getExe pkgs.selfPackages.csh-web-search;
          env_vars = [ "DEEPSEEK_API_KEY" ];
        };
        model_providers.deepseek = {
          name = "deepseek";
          base_url = "https://api.deepseek.com/";
          wire_api = "responses";
          env_key = "DEEPSEEK_API_KEY";
        };
      };
      csh = pkgs.writeShellApplication {
        name = "csh";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          export CODEX_HOME=${lib.escapeShellArg cshHome}
          DEEPSEEK_API_KEY="$(cat ${config.constants.resources.userSecretPaths.deepseek_api_key})"
          export DEEPSEEK_API_KEY

          exec ${lib.getExe llmAgents.codex} "$@"
        '';
      };
    in
    {
      home.file.".local/share/csh/models.json".source = ./csh/models.json;

      # Codex persists trust levels, MCP servers, and TUI settings by
      # rewriting config.toml, which fails against the read-only symlink that
      # home.file creates. Keep a real copy instead: refresh it from the store
      # while it is still untouched, then leave local edits alone.
      home.activation.cshConfig = lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] ''
        if [ -L "${cshConfigFile}" ] || [ ! -e "${cshConfigFile}" ] \
          || ${lib.getExe' pkgs.coreutils "cmp"} -s "${cshConfigFile}" "${cshConfigDeployed}"; then
          $DRY_RUN_CMD ${lib.getExe' pkgs.coreutils "install"} -m 0644 "${cshConfig}" "${cshConfigFile}"
        fi
        $DRY_RUN_CMD ${lib.getExe' pkgs.coreutils "install"} -m 0644 "${cshConfig}" "${cshConfigDeployed}"
      '';

      # Local skill packages and upstream sources pinned by revision and tree
      # hash. Herdr's `.agents/skills` holds internal workflows, so its public
      # skill is pinned as a single file.
      skills.install = [
        pkgs.selfPackages.ask-astra
        (builtins.fetchTree {
          type = "github";
          owner = "mattpocock";
          repo = "skills";
          rev = "c55ee46073ed923f86ce59a5eb3b6d895095d1b7";
          narHash = "sha256-L3CpIT2DeI+fUFl9fcygojtQo2DzEen69rMD1XqR1vM=";
        })
        (builtins.fetchTree {
          type = "github";
          owner = "ayghri";
          repo = "i-have-adhd";
          rev = "b15d0be58f55b33972ba3e39709e0e5208ef30cb";
          narHash = "sha256-wnD5crIal23Vtk6GReG2vCkjDuhrpmhWXvrNUq5mZfE=";
        })
        (builtins.fetchurl {
          url = "https://raw.githubusercontent.com/herdrdev/herdr/7b675f42af35508eab66ac42fe1598628597a893/skills/herdr/SKILL.md";
          sha256 = "sha256-I3rSqy2BI+K7N5VtOkHu0UHy0ip8NuQVt4dsA5dnkJk=";
        })
      ];

      programs = {
        herdr = {
          enable = true;
          plugins = {
            inherit (pkgs.selfPackages) herdr-projects herdr-reviewr;
          };
          settings = {
            onboarding = false;
            session.resume_agents_on_restore = true;
            keys.command = [
              {
                key = "alt+r";
                type = "plugin_action";
                command = "persiyanov.reviewr.toggle";
              }
            ];
            theme.name = "terminal";
            ui.toast.delivery = "system";
          };
        };
      };

      home.packages = [
        csh
      ]
      ++ (with llmAgents; [
        codex
        cursor-agent
        opencode
        dsh
      ])
      ++ (with pkgs; [
        bubblewrap
        jq
        python3
        selfPackages.zed-delta
      ]);
    };
}
