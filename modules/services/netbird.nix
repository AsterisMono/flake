{
  flake.modules.nixos.netbird = { config, ... }: {
    sops.secrets.netbird_setup_key = {
      format = "yaml";
      sopsFile = config.constants.resources.getSecretPath "netbird.yaml";
      restartUnits = [ "netbird-sne-connect-login.service" ];
    };
    services.netbird.clients.sne-connect = {
      port = 51820;
      environment.NB_MANAGEMENT_URL = "https://connect.sne.moe:443";
      # NetBird's own SSH server binds the NetBird interface on port 22 and
      # requires a NetBird JWT, which shadows the system sshd for anyone
      # connecting over NetBird. Keep standard SSH keys working instead.
      config.ServerSSHAllowed = false;
      login = {
        enable = true;
        setupKeyFile = config.sops.secrets.netbird_setup_key.path;
        systemdDependencies = [ "sops-install-secrets.service" ];
      };
    };

    # Leave the firewall on, but let the NetBird tunnel through without
    # filtering. On servers the client's interface is `nb-sne-connect`.
    networking.firewall.trustedInterfaces = [
      config.services.netbird.clients.sne-connect.interface
    ];
  };
}
