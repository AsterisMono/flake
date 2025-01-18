{ lib, osConfig, pkgs, ... }:
let
  cfg = osConfig.amono.desktop.hyprland.enable;
in
{
  config = lib.mkIf cfg {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = false; # uwsm
      extraConfig = builtins.readFile ./hyprland.conf;
    };

    programs.fuzzel = {
      enable = true;
    };

    services.mako = {
      enable = true;
      font = lib.mkForce "Torus 10";
      borderSize = 0;
      padding = "10";
    };

    services.udiskie.enable = true;
  };
}
