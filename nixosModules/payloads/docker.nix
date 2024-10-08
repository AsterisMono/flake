{ options, lib, config, ... }:
{
  options.amono.payload.docker.enableWatchTower = {
    type = lib.types.bool;
    default = true;
    description = "Enable WatchTower to auto update docker images";
  };

  config = {
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.watch-tower = {
      image = "containrrr/watchtower";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
    };
  };
}
