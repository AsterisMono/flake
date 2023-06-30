{ config, pkgs, lib,  ... }:

{
  services.xserver = {
    enable = true;
    layout = "us";
    displayManager.gdm.enable = true;
    desktopManager.gnome = {
      enable = true;
    };
    excludePackages = with pkgs; [
      xterm
    ];
  };

  environment.gnome.excludePackages = (with pkgs; [
    gnome-tour
    gnome-connections
    eolie
  ]) ++ (with pkgs.gnome; [
    epiphany
  ]);

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-kde ];

  environment.systemPackages = (with pkgs.gnomeExtensions; [
    appindicator
    dash-to-dock
    system-monitor
    xremap
    blur-my-shell
  ]) ++ (with pkgs; [
    arc-theme
    tela-icon-theme
    adw-gtk3
  ]);

  # Override pulseaudio
  # I have no idea who enabled this
  hardware.pulseaudio.enable = lib.mkForce false;

  qt.platformTheme = "gnome";
}