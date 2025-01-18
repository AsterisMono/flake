{ lib, osConfig, pkgs, ... }:
let
  cfg = osConfig.amono.desktop.hyprland.enable;
  cursorPackage = pkgs.capitaine-cursors;
  cursorThemeName = "capitaine-cursors-white";
  cursorSize = 32;
in
{
  config = lib.mkIf cfg {
    wayland.windowManager.hyprland = {
      enable = true;
      settings = lib.mkIf osConfig.hardware.nvidia.modesetting.enable {
        env = [
          "LIBVA_DRIVER_NAME,nvidia"
          "XDG_SESSION_TYPE,wayland"
          "GBM_BACKEND,nvidia-drm"
          "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        ];
      };
      extraConfig = builtins.readFile ./hyprland.conf;
    };

    services.hyprpaper = {
      enable = true;
      settings = {
        splash = false;
        preload = [ "${./wall2.png}" ];
        wallpaper = [ ",${./wall2.png}" ];
      };
    };

    programs.wofi = {
      enable = true;
      settings = {
        no_actions = true;
      };
      style = builtins.readFile ./wofi.css;
    };

    services.mako = {
      enable = true;
      font = "Torus 10";
      backgroundColor = "#E66868";
      textColor = "#F3EAD3";
      borderSize = 0;
      padding = "10";
    };

    home.packages = with pkgs; [
      adw-gtk3
    ];

    # this sets the XCURSOR variables
    home.pointerCursor = {
      package = cursorPackage;
      name = cursorThemeName;
      size = cursorSize;
    };

    gtk = {
      enable = true;

      iconTheme = {
        name = "breeze";
        package = pkgs.kdePackages.breeze-icons;
      };

      cursorTheme = {
        name = cursorThemeName;
        package = cursorPackage;
        size = cursorSize;
      };

      theme = {
        name = "Breeze";
        package = pkgs.kdePackages.breeze-gtk;
      };
    };
  };
}
