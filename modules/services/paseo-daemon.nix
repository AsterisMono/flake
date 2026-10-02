{ config, inputs, ... }:
{
  flake.modules.aspects.paseo-daemon.imports = [ inputs.self.modules.aspects.agent-providers ];

  flake.modules.nixos.paseo-daemon =
    { lib, pkgs, ... }:
    let
      paseoDaemon = pkgs.selfPackages.paseo-daemon;
      agentPackages = config.agentProviders.packages pkgs;
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

      systemd.services.paseo-daemon = {
        description = "Paseo host for coding agents and terminals";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];

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
