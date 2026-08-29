{
  flake.modules.nixos.nvidia = {
    hardware = {
      graphics.enable = true;
      nvidia = {
        modesetting.enable = true;
        open = true;
      };
    };

    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
