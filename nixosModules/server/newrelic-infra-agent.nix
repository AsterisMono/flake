{ config, secrets, lib, ... }:
{
  options = {
    amono.server.newRelicAgent.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the New Relic Infrastructure Agent and auto register the host";
    };
  };
  config = lib.mkIf config.amono.server.newRelicAgent.enable {
    services.newrelic-infra = {
      enable = true;
      configFile = "${secrets}/newrelic-infra.yml";
    };
  };
}
