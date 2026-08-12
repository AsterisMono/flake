{
  flake.modules.nixos.services-sing-box = { config, ... }: {
    sops.secrets.sing_box_config = {
      format = "json";
      sopsFile = config.constants.resources.getSecretPath "sing-box.json";
      path = "/etc/sing-box/config.json";
      key = "";
      restartUnits = [ "sing-box.service" ];
    };
    services.sing-box.enable = true;
  };
}
