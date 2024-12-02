{ osConfig, lib, ... }:
let
  proxyConfig = osConfig.amono.proxy;
in
{
  programs.ssh = lib.mkIf proxyConfig.enable {
    extraConfig = ''
      ProxyCommand /run/current-system/sw/bin/nc -X 5 -x 127.0.0.1:${toString proxyConfig.port} %h %p
    '';
  };
}
