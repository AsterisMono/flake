_: {
  flake.modules.nixos.networkmanager = {
    networking.networkmanager.enable = true;
  };

  flake.modules.homeManager.networkmanager = {
    services.network-manager-applet.enable = true;
  };
}
