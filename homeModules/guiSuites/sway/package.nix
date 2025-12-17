{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.wayland.windowManager.sway;
in
{
  wayland.windowManager.sway = {
    enable = true;
    systemd.enable = true;
    wrapperFeatures.gtk = true;
    config = {
      modifier = "Mod4";
      bars = [ ];
      output.HDMI-A-1 = {
        mode = "2560x1440@75hz";
        scale = "1.25";
      };
      terminal = "ghostty";
      menu = "vicinae toggle";
      gaps.smartBorders = "on";
      workspaceAutoBackAndForth = true;
      window.titlebar = false;
      floating.titlebar = false;
      keybindings =
        let
          inherit (cfg.config) modifier;
        in
        builtins.removeAttrs
          (lib.mkOptionDefault {
            "${modifier}+q" = "exec ${cfg.config.terminal}";
            "${modifier}+c" = "kill";
            "${modifier}+space" = "exec ${cfg.config.menu}";
            "${modifier}+Alt+Space" = "focus mode_toggle";
            "${modifier}+Shift+s" = ''exec sh -c "slurp | grim -g - - | wl-copy"'';
          })
          [
            "${modifier}+Return"
            "${modifier}+Shift+q"
            "${modifier}+d"
          ];
    };
  };

  home.packages = with pkgs; [
    brightnessctl
    swayidle
    swaylock
    wl-clipboard
    mako
    waybar
    slurp
    grim
  ];

  services.gnome-keyring.enable = true;

  xdg.portal.config.common.default = "*";
}
