{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    clash clash-geoip
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
}
