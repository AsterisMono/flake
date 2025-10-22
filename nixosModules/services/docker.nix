{
  config,
  lib,
  ...
}:
{
  options.noa.docker = {
    enableWatchTower = lib.mkEnableOption "Watchtower auto update";
    useRegistryMirror = lib.mkEnableOption "Registry mirror";
  };

  config = {
    virtualisation.podman = {
      enable = true;
      dockerSocket.enable = true;
      dockerCompat = true;
    };
    virtualisation.oci-containers.backend = "podman";
    virtualisation.oci-containers.containers.watch-tower = lib.mkIf config.noa.docker.enableWatchTower {
      image = "containrrr/watchtower";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
    };
  };
}
