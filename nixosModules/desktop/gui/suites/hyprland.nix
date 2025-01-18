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
      hyprshot
      cliphist
      wl-clip-persist
      pavucontrol
      udiskie
      blueman
      nautilus
      nautilus-open-any-terminal
      loupe
      amberol
    ];

    services.greetd = {
      enable = true;
    };

    services.gnome.gnome-keyring.enable = true;

    services.tumbler.enable = true;
  };
}
