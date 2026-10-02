{ config, inputs, ... }:
let
  providerPackages = config.agentProviders.packages;
in
{
  flake.modules.aspects.paseo-daemon.imports = [ inputs.self.modules.aspects.agent-providers ];

  flake.modules.nixos.paseo-daemon =
    {
      config,
      lib,
      pkgs,
      utils,
      ...
    }:
    let
      paseoDaemon = pkgs.selfPackages.paseo-daemon;
      agentPackages = providerPackages pkgs;
      secretNames = [
        "deepseek_api_key"
        "openrouter_api_key"
        "codex_auth_json"
        "cursor_auth_json"
      ];
      initializeAuth =
        utils.escapeSystemdExecArgs [
          (lib.getExe pkgs.python3)
          ../apps/agents/initialize-auth.py
          "--home"
          "/var/lib/paseo"
        ]
        # Keep systemd's credential-directory specifier unescaped.
        + " --codex-auth %d/codex_auth_json --cursor-auth %d/cursor_auth_json --deepseek-key %d/deepseek_api_key --openrouter-key %d/openrouter_api_key";
    in
    {
      users.groups.paseo = { };
      users.users.paseo = {
        isSystemUser = true;
        group = "paseo";
        home = "/var/lib/paseo";
        shell = pkgs.bashInteractive;
      };

      environment.systemPackages = [ paseoDaemon ] ++ agentPackages;

      sops.secrets = lib.genAttrs secretNames (_: {
        restartUnits = [ "paseo-daemon.service" ];
      });

      systemd.services.paseo-daemon = {
        description = "Paseo host for coding agents and terminals";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        requires = [ "sops-install-secrets.service" ];
        after = [
          "network-online.target"
          "sops-install-secrets.service"
        ];

        path = [
          paseoDaemon
        ]
        ++ agentPackages
        ++ (with pkgs; [
          bashInteractive
          git
          openssh
          nix
          ripgrep
        ]);

        environment = {
          HOME = "/var/lib/paseo";
          PASEO_HOME = "/var/lib/paseo/.paseo";
          PASEO_LISTEN = lib.mkDefault "127.0.0.1:6767";
          PASEO_NODE_ENV = "production";
          SHELL = lib.getExe pkgs.bashInteractive;
          # Leave relay enablement in writable config.json: pairing saves it
          # there, and a deployment env override would prevent later changes.
        };

        serviceConfig = {
          Type = "simple";
          User = "paseo";
          Group = "paseo";
          StateDirectory = "paseo";
          StateDirectoryMode = "0700";
          WorkingDirectory = "/var/lib/paseo";
          LoadCredential = map (name: "${name}:${config.sops.secrets.${name}.path}") secretNames;
          ExecStartPre = initializeAuth;
          ExecStart = "${lib.getExe paseoDaemon} daemon run";
          Restart = "on-failure";
          RestartSec = 5;
          KillMode = "control-group";
          TimeoutStopSec = 30;
          UMask = "0077";
          NoNewPrivileges = true;
          ProtectSystem = "full";
          ProtectHome = true;
          PrivateTmp = true;
        };
      };
    };
}
