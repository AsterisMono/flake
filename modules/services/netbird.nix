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
      login = {
        enable = true;
        setupKeyFile = config.sops.secrets.netbird_setup_key.path;
        systemdDependencies = [ "sops-install-secrets.service" ];
      };
    };
  };
}
