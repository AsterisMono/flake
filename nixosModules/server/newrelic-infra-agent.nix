{ secrets, ... }:
{
  services.newrelic-infra = {
    enable = true;
    configFile = "${secrets}/newrelic-infra.yml";
  };
}
