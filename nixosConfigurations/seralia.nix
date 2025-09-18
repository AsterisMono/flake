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
    exporters.node = {
      enable = true;
      enabledCollectors = [
        "systemd"
      ];
      disabledCollectors = [ "textfile" ];
    };
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.exporters.node.port}"
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
        enforce_domain = true;
        enable_gzip = true;
        domain = grafanaDomain;
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
