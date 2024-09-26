{ secrets, hostname, ... }:
{
  services.datadog-agent = {
    enable = true;
    inherit hostname;
    site = "datadoghq.eu";
    apiKeyFile = "${secrets}/dd-api-key.txt";
    enableTraceAgent = true;
    enableLiveProcessCollection = true;
    extraIntegrations = {
      docker = pythonPackages: [ ]; # docker integration is written in go
    };
  };
}
