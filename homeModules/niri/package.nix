{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.niri = {
    package = pkgs.niri;
    settings = {
      hotkey-overlay.skip-at-startup = true;
      clipboard.disable-primary = true;

      spawn-at-startup = [
        { command = [ "waybar" ]; }
      ];

      input = {
        warp-mouse-to-focus.enable = true;
        workspace-auto-back-and-forth = true;
      };

      binds =
        with config.lib.niri.actions;
        let
          sh = spawn "sh" "-c";
          wpctl = lib.getExe' pkgs.wireplumber "wpctl";
        in
        {
          "Mod+D".action = spawn "fuzzel";
          "Mod+Q".action = spawn "alacritty";
          "Mod+C".action = close-window;
          "Mod+O".action = toggle-overview;

          "Mod+H".action = focus-column-left;
          "Mod+J".action = focus-window-down;
          "Mod+K".action = focus-window-up;
          "Mod+L".action = focus-column-right;

          "Mod+Shift+H".action = move-column-left;
          "Mod+Shift+J".action = move-window-down;
          "Mod+Shift+K".action = move-window-up;
          "Mod+Shift+L".action = move-column-right;

          "Mod+Ctrl+H".action = focus-monitor-left;
          "Mod+Ctrl+J".action = focus-monitor-down;
          "Mod+Ctrl+K".action = focus-monitor-up;
          "Mod+Ctrl+L".action = focus-monitor-right;

          "Mod+Shift+Ctrl+H".action = move-column-to-monitor-left;
          "Mod+Shift+Ctrl+J".action = move-column-to-monitor-down;
          "Mod+Shift+Ctrl+K".action = move-column-to-monitor-up;
          "Mod+Shift+Ctrl+L".action = move-column-to-monitor-right;

          "Mod+BracketLeft".action = consume-or-expel-window-left;
          "Mod+BracketRight".action = consume-or-expel-window-right;
          "Mod+Comma".action = consume-window-into-column;
          "Mod+Period".action = expel-window-from-column;

          "Mod+R".action = switch-preset-column-width;
          "Mod+Shift+R".action = switch-preset-window-height;
          "Mod+Ctrl+R".action = reset-window-height;
          "Mod+F".action = maximize-column;
          "Mod+Shift+F".action = fullscreen-window;
          "Mod+Ctrl+F".action = expand-column-to-available-width;
          "Mod+Shift+C".action = center-column;
          "Mod+Ctrl+C".action = center-visible-columns;

          "Mod+Minus".action = set-column-width "-10%";
          "Mod+Equal".action = set-column-width "+10%";
          "Mod+Shift+Minus".action = set-window-width "-10%";
          "Mod+Shift+Equal".action = set-window-width "+10%";

          "Mod+V".action = toggle-window-floating;
          "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;

          "Mod+Shift+S".action = screenshot;
          "Mod+Shift+P".action = screenshot-window;
          # "Mod+Shift+Ctrl+P".action = screenshot-screen;

          "Mod+Shift+E".action = quit;

          "XF86AudioRaiseVolume".action = sh "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 10%+";
          "XF86AudioLowerVolume".action = sh "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 10%-";
        };
    };
  };

  programs.fuzzel = {
    enable = true;
  };

  programs.alacritty = {
    enable = true;
  };

  services.mako = {
    enable = true;
  };

  programs.waybar = {
    enable = true;
  };

  home.packages = with pkgs; [
    libnotify
    wl-clipboard
    brightnessctl
    swaybg
    wl-clip-persist
  ];
}
