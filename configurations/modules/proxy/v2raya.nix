{ config, pkgs, lib, ... }:
let
  v2raya = config.nur.repos.rewine.v2raya;
in
{
  environment.systemPackages = [
    v2raya
  ];

  systemd.services.v2raya = {
    description = "V2rayA Service";
    after = [ "network.target" "nss-lookup.target" "iptables.service" "ip6tables.service" ];
    wants = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "root";
      LimitNPROC = "500";
      LimitNOFILE = "1000000";
      ExecStart = ''${v2raya}/bin/v2rayA --log-disable-timestamp'';
      Environment = "V2RAYA_LOG_FILE=/var/log/v2raya/v2raya.log";
      Restart = "on-failure";
    };
  };
}
