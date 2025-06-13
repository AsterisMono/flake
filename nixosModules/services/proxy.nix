{
  lib,
  config,
  secrets,
  ...
}:
let
  cfg = config.noa.proxy;
  proxy = "127.0.0.1:${toString cfg.port}";
  httpProxy = "http://${proxy}";
  socksProxy = "socks5://${proxy}";
in
{
  options.noa.proxy = {
    tunMode = lib.mkEnableOption "Enable TUN Mode for mihomo proxy";
    port = lib.mkOption {
      default = 7890;
    };
  };

  config = {
    services.mihomo = {
      enable = true;
      inherit (cfg) tunMode;
      configFile = secrets.mihomoConfig;
    };

    networking.proxy = lib.mkIf (!cfg.tunMode) {
      inherit httpProxy;
      httpsProxy = httpProxy;
      allProxy = socksProxy;
      noProxy = "localhost,127.0.0.1,10.96.0.0/12,192.168.59.0/24,192.168.49.0/24,192.168.39.0/24"; # minikube
    };

    # iptables based firewall needs to be disabled
    # NixOS employs firewall by default
    # And it's blocking inbound connections on 192.18.0.1/16
    # Effectively breaking tun mode
    # However NixOS config networking.firewall doesn't support declarative ip-range rules, only ports
    # sus
    # TODO: use priority
    networking.firewall.enable = lib.mkForce (!cfg.tunMode);
  };
}
