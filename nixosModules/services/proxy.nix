{
  lib,
  config,
  secretsPath,
  ...
}:
{
  config = {
    sops.secrets.mihomoConfig = {
      format = "yaml";
      sopsFile = "${secretsPath}/mihomoConfig.yaml";
      key = "";
      restartUnits = [ "mihomo.service" ];
    };

    services.mihomo = {
      enable = true;
      tunMode = true;
      configFile = config.sops.secrets.mihomoConfig.path;
    };

    # iptables based firewall needs to be disabled
    # NixOS employs firewall by default
    # And it's blocking inbound connections on 192.18.0.1/16
    # Effectively breaking tun mode
    # However NixOS config networking.firewall doesn't support declarative ip-range rules, only ports
    # sus
    networking.firewall.enable = lib.mkForce false;
  };
}
