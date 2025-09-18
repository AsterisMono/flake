{
  config,
  nixosModules,
  ...
}:
let
  grafanaDomain = "observatory.requiem.garden";
in
{
  imports = with nixosModules; [
    diskLayouts.btrfs
    roles.server
    services.tailscale
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
      # blackbox = {
      #   enable = true;
      #   port = 9115;
      #   listenAddress = "127.0.0.1";
      # };
    };
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.exporters.node.port}"
              "ivy:9100"
            ];
          }
        ];
      }
      {
        job_name = "bird";
        static_configs = [
          {
            targets = [
              "ivy:9324"
            ];
          }
        ];
      }
      {
        job_name = "wireguard";
        static_configs = [
          {
            targets = [
              "ivy:9586"
            ];
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
