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
    virtualisation.docker = {
      enable = true;
      daemon.settings = lib.mkIf config.noa.docker.useRegistryMirror {
        registry-mirrors = [ "https://docker.1ms.run" ];
      };
    };
    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.watch-tower = lib.mkIf config.noa.docker.enableWatchTower {
      image = "containrrr/watchtower";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
    };
  };
}
