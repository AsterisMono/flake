{
  flake.modules.nixos.nvidia =
    { config, ... }:
    {
      hardware = {
        graphics.enable = true;
        nvidia = {
          modesetting.enable = true;
          open = true;
          package = config.boot.kernelPackages.nvidiaPackages.latest;
        };
      };

      boot.initrd.kernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_drm"
      ];

      services.xserver.videoDrivers = [ "nvidia" ];
    };
}
