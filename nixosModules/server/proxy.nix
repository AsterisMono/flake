{ lib, config, secrets, ... }:
let
  httpProxy = "http://127.0.0.1:7890";
  socksProxy = "socks5://127.0.0.1:7890";
  cfg = config.amono.server.proxy;
in
{
  config = lib.mkIf cfg.enable {
    services.mihomo = {
      enable = true;
      configFile = "${secrets}/mihomoConfig.yaml";
    };
    networking.proxy = {
      inherit httpProxy;
      httpsProxy = httpProxy;
      allProxy = socksProxy;
    };
  };
}
