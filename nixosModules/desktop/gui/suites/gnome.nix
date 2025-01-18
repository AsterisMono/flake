{ config, pkgs, lib, ... }:
let
  cfg = config.amono.desktop.gnome.enable;
in
{
  config = lib.mkIf cfg {
    services.xserver = {
      enable = true;

      displayManager.gdm = {
        enable = true;
        autoSuspend = false;
      };

      desktopManager.gnome.enable = true;

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
      epiphany
      tali
      iagno
      hitori
      atomix
      gnome-music
    ]);

    programs.xwayland.enable = true;
    programs.xwayland.package = pkgs.xwayland;

    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];

    environment.systemPackages = (with pkgs.gnomeExtensions; [
      appindicator
      dash-to-dock
      system-monitor
      xremap
      blur-my-shell
      kimpanel
    ]) ++ (with pkgs; [
      pop-gtk-theme
      pop-icon-theme
      vimix-icon-theme
      vimix-gtk-themes
      adw-gtk3
      gnome.adwaita-icon-theme
      gnome.gnome-tweaks
      maia-icon-theme
    ]);

    # Override pulseaudio
    # I have no idea who enabled this
    hardware.pulseaudio.enable = lib.mkForce false;

    qt.platformTheme = "gnome";
  };
}
