listenAddress:
{ pkgs, ... }:
{
  services.prometheus.exporters.blackbox = {
    enable = true;
    port = 9115;
    openFirewall = true;
    inherit listenAddress;
    configFile = pkgs.writeText "blackbox_config.yml" ''
      modules:
        heartbeat_icmp:
          prober: icmp
          timeout: 5s
    '';
  };
}
