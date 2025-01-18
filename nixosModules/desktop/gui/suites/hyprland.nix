{ config, pkgs, lib, ... }:
let
  cfg = config.amono.desktop.hyprland.enable;
in
{
  config = lib.mkIf cfg {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    environment.systemPackages = with pkgs;[
      # Libraries
      libnotify
      lxqt.lxqt-policykit
      wl-clipboard
      libsecret
      libsForQt5.qt5.qtwayland
      kdePackages.qtwayland
      # Applications
      hyprpaper
      hyprshot
      cliphist
      wl-clip-persist
      pavucontrol
      blueman
      nautilus
      nautilus-open-any-terminal
      loupe
      amberol
    ];

    services.xserver.displayManager.gdm = {
      enable = true;
    };

    services.gnome.gnome-keyring.enable = true;
    security.pam.services.gdm-password.enableGnomeKeyring = true;

    services.udisks2.enable = true;
  };
}
