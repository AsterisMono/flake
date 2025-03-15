{
  lib,
  osConfig,
  pkgs,
  type,
  ...
}:
let
  cfg = if type == "desktop" then osConfig.amono.desktop.hyprland.enable else false;
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
