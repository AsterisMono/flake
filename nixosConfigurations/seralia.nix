{
  config,
  nixosModules,
  ...
}:
let
  grafanaDomain = "observatory.requiem.garden";
  thisTsAddress = "100.121.244.87";
in
{
  imports = with nixosModules; [
    diskLayouts.btrfs
    roles.server
    services.tailscale
    (services.prometheus-blackbox thisTsAddress)
  ];

  disko.devices.disk.main.device = "/dev/vda";

  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "10s";
    exporters = {
      node = {
        enable = true;
        port = 9100;
        listenAddress = "127.0.0.1";
        enabledCollectors = [
          "systemd"
        ];
        disabledCollectors = [ "textfile" ];
      };
    };
    scrapeConfigs = [
      {
        # Do not **ever** change the job name.
        # Been there, done that.
        # https://stackoverflow.com/questions/54704117/how-can-i-delete-old-jobs-from-prometheus
        job_name = "node_exporter";
        static_configs = [
          {
            targets = [
              "localhost:9100"
              "ivy:9100"
            ];
          }
        ];
      }
      {
        job_name = "bird_exporter";
        static_configs = [
          { targets = [ "ivy:9324" ]; }
        ];
      }
      {
        job_name = "wireguard_exporter";
        static_configs = [
          { targets = [ "ivy:9586" ]; }
        ];
      }
      {
        job_name = "blackbox_exporter";
        static_configs = [
          {
            targets = [
              "localhost:9115"
              "ivy:9115"
            ];
          }
        ];
      }
      {
        job_name = "blackbox_tsnet_heartbeats";
        metrics_path = "/probe";
        params = {
          module = [ "heartbeat_icmp" ];
        };
        static_configs = [
          {
            targets = [
              "ivy"
              "seralia"
              "derper"
            ];
          }
        ];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "${thisTsAddress}:9115";
          }
        ];
      }
      {
        job_name = "blackbox_dn42_peer_heartbeats";
        metrics_path = "/probe";
        params = {
          module = [ "heartbeat_icmp" ];
        };
        static_configs = [
          {
            # TODO: integrate into dn42 config
            targets = [
              "fdec:a476:db6e:ffff::2323:1" # 2323
              "fdd2:4372:796f:ffff::833:0" # 0994
              "fe80::803%dn42wg0803" # 0803
            ];
          }
        ];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "ivy:9115";
          }
        ];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        enable_gzip = true;
        root_url = "https://${grafanaDomain}/";
      };
      analytics.reporting_enabled = false;
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."${grafanaDomain}" = {
      addSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "noa@requiem.garden";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
