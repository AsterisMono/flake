{
  inputs,
  ...
}:
let
  herdrSkill = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/herdrdev/herdr/7b675f42af35508eab66ac42fe1598628597a893/skills/herdr/SKILL.md";
    sha256 = "sha256-I3rSqy2BI+K7N5VtOkHu0UHy0ip8NuQVt4dsA5dnkJk=";
  };
in
{
  flake-file.inputs = {
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  flake.modules.aspects.agents.imports = with inputs.self.modules.aspects; [
    herdr
  ];

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
          DEEPSEEK_API_KEY="$(cat ${config.sops.secrets.deepseek_api_key.path})"
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

      sops.secrets.deepseek_api_key = {
        format = "yaml";
        key = "deepseek_api_key";
        sopsFile = config.constants.resources.getSecretPath "deepseek.yaml";
      };

      programs = {
        herdr = {
          enable = true;
          plugins.reviewr = pkgs.selfPackages.herdr-reviewr;
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
