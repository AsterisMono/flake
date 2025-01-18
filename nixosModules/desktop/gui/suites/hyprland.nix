{ config, pkgs, lib, ... }:
let
  cfg = config.amono.desktop.hyprland.enable;
in
{
  config = lib.mkIf cfg {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    environment.systemPackages = with pkgs;[
      waybar
      mako
      wofi
      libnotify
      hyprpaper
      hyprshot
      kitty
      lxqt.lxqt-policykit
      wl-clipboard
      pavucontrol
      udiskie
      xfce.thunar
      xfce.ristretto
      blueman
      cliphist
      libsecret
    ];

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
          user = "greeter";
        };
      };
    };

    services.gnome.gnome-keyring.enable = true;

    services.tumbler.enable = true;
  };
}
