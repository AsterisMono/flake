{ lib, config, secrets, ... }:
{
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
  virtualisation.oci-containers.backend = "docker";
}
