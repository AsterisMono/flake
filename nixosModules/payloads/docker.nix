{ lib, config, secrets, ... }:
{
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers.new-relic-docker-agent = lib.mkIf config.amono.server.newRelicAgent.enable {
    image = "newrelic/infrastructure:latest";
    volumes = [
      "/:/host:ro"
      "/var/run/docker.sock:/var/run/docker.sock"
      "newrelic-infra:/etc/newrelic-infra"
    ];
    extraOptions = [
      "--cap-add=SYS_PTRACE"
      "--privileged"
      "--pid=host"
    ];
    environmentFiles = [
      "${secrets}/newrelic.env"
    ];
  };
}
