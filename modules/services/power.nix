_: {
  flake.modules.nixos.power = {
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
  };
}
