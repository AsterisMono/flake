{ lib, osConfig, pkgs, ... }:
let
  cfg = osConfig.amono.desktop.hyprland.enable;
in
{
  config = lib.mkIf cfg {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = false; # uwsm
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

    programs.fuzzel = {
      enable = true;
    };

    services.mako = {
      enable = true;
      font = lib.mkForce "Torus 10";
      borderSize = 0;
      padding = "10";
    };
  };
}
