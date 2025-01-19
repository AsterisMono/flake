{ osConfig, lib, ... }:
let
  cfg = osConfig.amono.desktop.hyprland.enable;
in
{
  config = lib.mkIf cfg {
    programs.alacritty = {
      enable = true;
      settings.window = {
        dynamic_padding = true;
        decorations = "None";
      };
    };
  };
}
