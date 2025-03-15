{
  osConfig,
  lib,
  type,
  ...
}:
let
  cfg = if type == "desktop" then osConfig.amono.desktop.hyprland.enable else false;
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
