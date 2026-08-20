_: {
  flake.modules.nixos.bluetooth = {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };

  flake.modules.homeManager.bluetooth = {
    services.blueman-applet.enable = true;
  };
}
