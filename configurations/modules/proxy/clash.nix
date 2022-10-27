{ config, pkgs, lib, ... }:
let
  clashProxy = "http://127.0.0.1:7890";
in
{
  environment.systemPackages = with pkgs; [
    clash
    clash-geoip
  ];

  systemd.services.clash = {
    description = "A rule based proxy in Go.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "cmiki"; # FIXME
      ExecStart = ''${pkgs.clash}/bin/clash'';
      Restart = "on-abort";
    };
  };

  networking.proxy = {
    httpProxy = clashProxy;
    httpsProxy = clashProxy;
    noProxy = "127.0.0.1,localhost,.localdomain";
  };

  programs.git.config = lib.mkIf (config.programs.git.enable == true) {
    http.proxy = clashProxy;
    https.proxy = clashProxy;
  };

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
