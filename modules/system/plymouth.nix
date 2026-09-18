{
  flake.modules.nixos.plymouth = {
    stylix.targets.plymouth.logoAnimated = false;

    boot = {
      plymouth.enable = true;
      consoleLogLevel = 3;
      initrd.verbose = false;
      kernelParams = [
        "quiet"
        "splash"
        "udev.log_level=3"
        "rd.udev.log_level=3"
        "rd.systemd.show_status=false"
      ];
    };
  };
}
