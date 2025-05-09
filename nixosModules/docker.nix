{
  config,
  lib,
  ...
}:
{
  options.noa.docker.enableWatchTower = {
    type = lib.types.bool;
    default = false;
    description = "Enable WatchTower to auto update docker images";
  };

  config = {
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.watch-tower = lib.mkIf config.noa.docker.enableWatchTower {
      image = "containrrr/watchtower";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
    };
  };
}
