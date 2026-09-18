_: {
  flake.modules.nixos.gdm = {
    services.displayManager.gdm.enable = true;
  };
}
