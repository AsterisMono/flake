{ config, pkgs, ... }:

{
  # Choose a proxy provider.
  imports = [
    ./clash.nix
  ];
  programs.proxychains = {
    enable = true;
    quietMode = true;
    proxies = {
      clash = {
        enable = true;
        type = "socks5";
        host = "127.0.0.1";
        port = 7891;
      };
    };
  };
}
