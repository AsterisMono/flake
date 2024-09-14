{ lib, config, secrets, ... }:
let
  httpProxy = "http://127.0.0.1:7890";
  socksProxy = "socks5://127.0.0.1:7890";
  cfg = config.amono.proxy;
in
{
  options = {
    amono.proxy = {
      enable = lib.mkEnableOption "Enable proxy";
      tunMode = lib.mkEnableOption "Enable TUN Mode";
    };
  };
  config = lib.mkIf cfg.enable {
    services.mihomo = {
      enable = true;
      inherit (cfg) tunMode;
      configFile = "${secrets}/mihomoConfig.yaml";
    };
    networking.proxy = lib.mkIf (!cfg.tunMode) {
      inherit httpProxy;
      httpsProxy = httpProxy;
      allProxy = socksProxy;
    };
    # iptables based firewall needs to be disabled
    # NixOS employs firewall by default
    # And it's blocking inbound connections on 192.18.0.1/16
    # Effectively breaking tun mode
    # However NixOS config networking.firewall doesn't support declarative ip-range rules, only ports
    # sus
    # TODO: use priority
    networking.firewall.enable = !cfg.tunMode;
  };
}