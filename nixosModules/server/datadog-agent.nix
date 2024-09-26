{ secrets, hostname, ... }:
{
  services.datadog-agent = {
    enable = true;
    inherit hostname;
    site = "datadoghq.eu";
    apiKeyFile = "${secrets}/dd-api-key.txt";
    enableTraceAgent = true;
    extraConfig = {
      process_config = {
        enabled = true;
        container_collection.enabled = true;
        process_collection.enabled = true;
      };
    };
  };
}
