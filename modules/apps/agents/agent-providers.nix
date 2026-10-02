{
  config,
  inputs,
  lib,
  ...
}:
let
  providerPackages = config.agentProviders.packages;
in
{
  options.agentProviders.packages = lib.mkOption {
    type = with lib.types; functionTo (listOf package);
    readOnly = true;
    internal = true;
    description = "TUI agent harnesses and runtime tools for a given package set.";
  };

  config = {
    flake.modules.aspects.agent-providers.imports = [ inputs.self.modules.aspects.agent-upstream ];

    agentProviders.packages =
      pkgs:
      let
        llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      in
      (with llmAgents; [
        codex
        cursor-agent
        pi
      ])
      ++ (with pkgs; [
        bubblewrap
        jq
        python3
      ]);

    flake.modules.homeManager.agent-providers =
      { pkgs, ... }:
      {
        key = "agent-providers";
        home.packages = config.agentProviders.packages pkgs;
      };

    flake.modules.nixos.agent-providers =
      {
        config,
        pkgs,
        utils,
        ...
      }:
      let
        username = config.constants.nvirellia.username;
        # Workstations use the personal account; headless machines use root.
        account = if config.users.users ? ${username} then username else "root";
        user = config.users.users.${account};
        cursorDirectory =
          if config.home-manager.users ? ${account} then
            "${config.home-manager.users.${account}.xdg.configHome}/cursor"
          else
            "${user.home}/.config/cursor";
        secretPaths = config.constants.resources.userSecretPaths;
        secretNames = [
          "deepseek_api_key"
          "openrouter_api_key"
          "codex_auth_json"
          "cursor_auth_json"
        ];
      in
      {
        # Workstations and the daemon can compose this same feature together.
        key = "agent-providers";
        environment.systemPackages = providerPackages pkgs;

        sops.secrets = lib.genAttrs secretNames (name: {
          format = "yaml";
          key = name;
          sopsFile = config.constants.resources.getSecretPath "agent-providers.yaml";
          path = secretPaths.${name};
          owner = account;
          inherit (user) group;
          mode = "0400";
          restartUnits = [ "agent-provider-auth.service" ];
        });

        systemd.services.agent-provider-auth = {
          description = "Initialize coding agent credentials";
          wantedBy = [ "multi-user.target" ];
          requires = [ "sops-install-secrets.service" ];
          after = [ "sops-install-secrets.service" ];
          unitConfig.RequiresMountsFor = [ user.home ];
          serviceConfig = {
            Type = "oneshot";
            User = account;
            Group = user.group;
            RemainAfterExit = true;
            UMask = "0077";
            ExecStart = utils.escapeSystemdExecArgs [
              (lib.getExe pkgs.python3)
              ./initialize-auth.py
              "--home"
              user.home
              "--codex-auth"
              secretPaths.codex_auth_json
              "--cursor-auth"
              secretPaths.cursor_auth_json
              "--cursor-dir"
              cursorDirectory
              "--deepseek-key"
              secretPaths.deepseek_api_key
              "--openrouter-key"
              secretPaths.openrouter_api_key
            ];
          };
        };
      };
  };
}
