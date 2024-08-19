{ secrets, ... }:
let
  httpProxy = "http://127.0.0.1:7890";
  socksProxy = "socks5://127.0.0.1:7890";
in
{
  services.mihomo = {
    enable = true;
    configFile = "${secrets}/mihomoConfig.yaml";
  };
  networking.proxy = {
    httpProxy = httpProxy;
    httpsProxy = httpProxy;
    allProxy = socksProxy;
  };
}
