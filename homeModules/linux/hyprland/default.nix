{ config, lib, osConfig, pkgs, ... }:

with lib;

let
  cfg = config.amonoHome.hyprland;
  cursorPackage = pkgs.capitaine-cursors;
  cursorThemeName = "capitaine-cursors-white";
  cursorSize = 32;
in
{
  options.amonoHome.hyprland = {
    enable = mkOption {
      type = types.bool;
      default = osConfig.programs.hyprland.enable;
      description = "是否启用 Hyprland 配置";
    };
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      settings = mkIf osConfig.hardware.nvidia.modesetting.enable {
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
