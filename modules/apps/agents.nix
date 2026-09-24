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

      sops.secrets.opencode_api_key = {
        format = "yaml";
        key = "opencode_api_key";
        sopsFile = config.constants.resources.getSecretPath "opencode.yaml";
        path = config.constants.resources.userSecretPaths.opencode_api_key;
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
      ocshHome = "${config.home.homeDirectory}/.local/share/ocsh";
      ocshConfigFile = "${ocshHome}/config.toml";
      ocshConfigDeployed = "${ocshHome}/.config.toml.deployed";
      # Upstream installs the v2 binary as `opencode2` so it can coexist with
      # v1 `opencode`. Expose it under the plain name as a real command, so
      # every consumer sees it: shells, scripts, and agent runners such as
      # paseo all resolve `opencode` through PATH.
      opencode = pkgs.writeShellScriptBin "opencode" ''
        exec ${lib.getExe llmAgents.opencode2} "$@"
      '';
      # Every shell runs the same Codex binary against a different provider, so
      # each gets its own CODEX_HOME and reads its API key from the file NixOS
      # provisioned for it.
      mkCodexShell =
        {
          name,
          codexHome,
          apiKeyEnv,
          apiKeyPath,
        }:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = [ pkgs.coreutils ];
          text = ''
            export CODEX_HOME=${lib.escapeShellArg codexHome}
            ${apiKeyEnv}="$(cat ${apiKeyPath})"
            export ${apiKeyEnv}

            exec ${lib.getExe llmAgents.codex} "$@"
          '';
        };
      # Codex persists trust levels, MCP servers, and TUI settings by rewriting
      # config.toml, which fails against the read-only symlink that home.file
      # creates. Keep a real copy instead: refresh it from the store while it is
      # still untouched, then leave local edits alone.
      mkCodexConfigActivation =
        {
          configFile,
          deployedFile,
          generated,
        }:
        lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] ''
          if [ -L "${configFile}" ] || [ ! -e "${configFile}" ] \
            || ${lib.getExe' pkgs.coreutils "cmp"} -s "${configFile}" "${deployedFile}"; then
            $DRY_RUN_CMD ${lib.getExe' pkgs.coreutils "install"} -m 0644 "${generated}" "${configFile}"
          fi
          $DRY_RUN_CMD ${lib.getExe' pkgs.coreutils "install"} -m 0644 "${generated}" "${deployedFile}"
        '';
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
      csh = mkCodexShell {
        name = "csh";
        codexHome = cshHome;
        apiKeyEnv = "DEEPSEEK_API_KEY";
        apiKeyPath = config.constants.resources.userSecretPaths.deepseek_api_key;
      };
      # OpenCode Go serves its subscription models over a Responses-compatible
      # endpoint, so Codex can drive them once it knows their metadata.
      ocshConfig = (pkgs.formats.toml { }).generate "ocsh-config.toml" {
        forced_login_method = "api";
        model = "deepseek-v4.1-flash";
        model_catalog_json = "${ocshHome}/models.json";
        model_provider = "opencode-go";
        model_reasoning_effort = "high";
        web_search = "disabled";
        model_providers.opencode-go = {
          name = "opencode-go";
          base_url = "https://opencode.ai/zen/go/v1";
          wire_api = "responses";
          env_key = "OPENCODE_API_KEY";
        };
      };
      ocsh = mkCodexShell {
        name = "ocsh";
        codexHome = ocshHome;
        apiKeyEnv = "OPENCODE_API_KEY";
        apiKeyPath = config.constants.resources.userSecretPaths.opencode_api_key;
      };
    in
    {
      home.file.".local/share/csh/models.json".source = ./csh/models.json;
      home.file.".local/share/ocsh/models.json".source = ./ocsh/models.json;

      home.activation.cshConfig = mkCodexConfigActivation {
        configFile = cshConfigFile;
        deployedFile = cshConfigDeployed;
        generated = cshConfig;
      };
      home.activation.ocshConfig = mkCodexConfigActivation {
        configFile = ocshConfigFile;
        deployedFile = ocshConfigDeployed;
        generated = ocshConfig;
      };

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
        ocsh
        opencode
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
