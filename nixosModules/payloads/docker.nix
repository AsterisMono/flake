{ options, lib, config, secrets, ... }:
let
  watchTowerEnable = config.amono.payload.docker.enableWatchTower;
in
{
  options.amono.payload.docker.enableWatchTower = {
    type = lib.types.bool;
    default = true;
    description = "Enable WatchTower to auto update docker images";
  };

  config = {
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";
  } // lib.mkIf watchTowerEnable {
    virtualisation.oci-containers.containers.watch-tower = {
      image = "containrrr/watchtower";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
    };
  };
}
