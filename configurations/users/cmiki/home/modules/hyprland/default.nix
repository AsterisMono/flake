{ osConfig, pkgs, ...}:
let
  hyprlandEnabled = osConfig.programs.hyprland.enable;
in
{
  wayland.windowManager.hyprland = {
    enable = hyprlandEnabled;
    extraConfig = builtins.readFile ./hyprland.conf;
  };

  services.hyprpaper = {
    enable = hyprlandEnabled;
    settings = {
      splash = false;
      preload = [
        # generators.mkValueStringDefault does not work with paths
        "${./wall2.png}"
      ];
      wallpaper = [
        ",${./wall2.png}"
      ];
    };
  };
}
