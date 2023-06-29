{ inputs, config, pkgs, lib, ... }:

{
  imports = [
    # Disabled - bugs do appear
    # ./bismuth.nix
  ];

  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
  };

  environment.systemPackages = with pkgs;[
    libsForQt5.yakuake
    kate
    materia-kde-theme
    papirus-icon-theme
    libsForQt5.qtstyleplugin-kvantum
  ];
}
