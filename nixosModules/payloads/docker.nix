{ lib, config, secrets, ... }:
{
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
}
