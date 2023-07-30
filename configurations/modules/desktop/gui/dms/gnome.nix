{ config, pkgs, lib,  ... }:

{
  services.xserver = {
    enable = true;
    layout = "us";

    displayManager.gdm = {
      enable = true;
      autoSuspend = false;
    };

    desktopManager.gnome = {
      enable = true;
      extraGSettingsOverridePackages = [ pkgs.gnome.mutter ];
      extraGSettingsOverrides = ''
        [org.gnome.mutter]
        experimental-features=['x11-randr-fractional-scaling']
      '';
    };

    excludePackages = with pkgs; [
      xterm
    ];
  };

  environment.gnome.excludePackages = (with pkgs; [
    gnome-tour
    gnome-connections
    eolie
    gnome-photos
  ]) ++ (with pkgs.gnome; [
    epiphany tali iagno hitori atomix gnome-music
  ]);

  programs.xwayland.enable = true;
  programs.xwayland.package = pkgs.xwayland;

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-kde ];

  environment.systemPackages = (with pkgs.gnomeExtensions; [
    appindicator
    dash-to-dock
    system-monitor
    xremap
    blur-my-shell
    kimpanel
  ]) ++ (with pkgs; [
    gnome.adwaita-icon-theme
    gnome.gnome-tweaks
  ]);

  # Override pulseaudio
  # I have no idea who enabled this
  hardware.pulseaudio.enable = lib.mkForce false;

  qt.platformTheme = "gnome";
}