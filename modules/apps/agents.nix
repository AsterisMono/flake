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

      sops.secrets.openrouter_management_key = {
        format = "yaml";
        key = "openrouter_management_key";
        sopsFile = config.constants.resources.getSecretPath "openrouter.yaml";
        path = config.constants.resources.userSecretPaths.openrouter_management_key;
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

      programs = {
        herdr = {
          enable = true;
          reviewr.enable = true;
          settings = {
            onboarding = false;
            session.resume_agents_on_restore = true;
            theme.name = "terminal";
            ui.toast.delivery = "system";
          };
        };
      };

      home.packages = [
        csh
      ]
      ++ [ llmAgents."grok-bot" ]
      ++ (with llmAgents; [
        codex
        cursor-agent
        opencode2
        dsh
        pi
        paseo-desktop
      ])
      ++ (with pkgs; [
        bubblewrap
        jq
        python3
        selfPackages.zed-delta
      ]);
    };
}
