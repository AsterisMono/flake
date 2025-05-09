{ osConfig, ... }:
let
  proxyPort = osConfig.noa.proxy.port;
in
{
  programs.ssh = {
    extraConfig = ''
      ProxyCommand /run/current-system/sw/bin/nc -X 5 -x 127.0.0.1:${toString proxyPort} %h %p
    '';
  };
}
