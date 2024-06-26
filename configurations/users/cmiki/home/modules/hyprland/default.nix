{ osConfig, ... }:
let
  hyprlandEnabled = osConfig.programs.hyprland.enable;
in
{
  imports = [
    ./waybar.nix
  ];

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

  programs.wofi = {
    enable = hyprlandEnabled;
    settings = {
      no_actions = true;
    };
    style = builtins.readFile ./wofi.css;
  };

  services.mako = {
    enable = hyprlandEnabled;
    font = "Torus 10";
    backgroundColor = "#E66868";
    textColor = "#F3EAD3";
    borderSize = 0;
    padding = "10";
  };
}
