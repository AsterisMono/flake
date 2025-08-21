{
  config,
  lib,
  pkgs,
  assetsPath,
  ...
}:
# https://github.com/jetjinser/flake/blob/master/hosts/dorothy/desktop/niri.nix
# https://github.com/ryan4yin/nix-config/tree/main/home/linux/gui/niri
# Thank you jinser & ryan4yin!
{
  imports = [ ../utils/wayland.nix ];

  programs.niri = {
    package = pkgs.niri;
    settings = {
      hotkey-overlay.skip-at-startup = true;
      clipboard.disable-primary = true;
      prefer-no-csd = true;

      outputs = {
        "Xiaomi Corporation Mi Monitor 5877500021251".scale = 1.75;
      };

      layout = {
        default-column-width.proportion = 0.5;
        # https://github.com/YaLTeR/niri/wiki/Overview#backdrop-customization
        background-color = "transparent";
        always-center-single-column = true;
      };

      cursor = {
        hide-when-typing = true;
      };

      input = {
        workspace-auto-back-and-forth = true;
      };

      overview.workspace-shadow.enable = false;

      binds =
        with config.lib.niri.actions;
        let
          sh = spawn "sh" "-c";
          wpctl = lib.getExe' pkgs.wireplumber "wpctl";
        in
        {
          "Mod+D".action = spawn "fuzzel";
          "Mod+Q".action = spawn "alacritty";
          "Mod+C" = {
            action = close-window;
            repeat = false;
          };
          "Mod+O" = {
            action = toggle-overview;
            repeat = false;
          };

          "Mod+H".action = focus-column-left;
          "Mod+J".action = focus-window-or-workspace-down;
          "Mod+K".action = focus-window-or-workspace-up;
          "Mod+L".action = focus-column-right;

          "Mod+Shift+H".action = move-column-left;
          "Mod+Shift+J".action = move-window-down;
          "Mod+Shift+K".action = move-window-up;
          "Mod+Shift+L".action = move-column-right;

          "Mod+Ctrl+H".action = focus-monitor-left;
          "Mod+Ctrl+J".action = focus-monitor-down;
          "Mod+Ctrl+K".action = focus-monitor-up;
          "Mod+Ctrl+L".action = focus-monitor-right;

          "Mod+U".action = focus-workspace-down;
          "Mod+I".action = focus-workspace-up;

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

          "XF86AudioRaiseVolume" = {
            action = sh "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 10%+";
            allow-when-locked = true;
          };
          "XF86AudioLowerVolume" = {
            action = sh "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 10%-";
            allow-when-locked = true;
          };
          "XF86AudioMute" = {
            action = sh "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
            allow-when-locked = true;
          };
        };

      layer-rules = [
        {
          matches = [ { namespace = "^notifications$"; } ];
          block-out-from = "screencast";
        }
        # https://github.com/sodiboo/niri-flake/pull/1063
        {
          matches = [ { namespace = "^wallpaper$"; } ];
          place-within-backdrop = true;
        }
      ];

      window-rules = [
        {
          geometry-corner-radius = {
            bottom-left = 8.0;
            bottom-right = 8.0;
            top-left = 8.0;
            top-right = 8.0;
          };
          clip-to-geometry = true;
        }
        {
          matches = [
            { app-id = "^org\.telegram\.desktop$"; }
            { app-id = "^QQ$"; }
          ];
          block-out-from = "screencast";
        }
        {
          matches = [
            {
              app-id = "^QQ$";
              title = "^(图片查看)|(视频播放)器$";
            }
            {
              app-id = "^org\.telegram\.desktop$";
              title = "^Media viewer$";
            }
            {
              app-id = "^firefox$";
              title = "^Picture-in-Picture$";
            }
          ];
          open-floating = true;
          default-window-height.proportion = 0.65;
          default-column-width.proportion = 0.65;
        }
      ];
    };
  };

  programs.fuzzel = {
    enable = true;
  };

  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        decorations = "None";
        opacity = 0.85;
        dynamic_padding = true;
      };
      font = {
        normal = {
          family = "FiraCode Nerd Font Mono";
          style = "Retina";
        };
        bold = {
          family = "FiraCode Nerd Font Mono";
          style = "SemiBold";
        };
      };
      cursor = {
        style = {
          shape = "Beam";
          blinking = "Never";
        };
        unfocused_hollow = false;
      };
    };
  };

  services.mako = {
    enable = true;
  };

  systemd.user.services = {
    swaybg = {
      Unit = {
        Description = "swaybg - show wallpaper";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        Requisite = [ "graphical-session.target" ];
      };
      Service =
        let
          show = pkgs.writeShellApplication {
            name = "show-wallpaper";
            runtimeInputs = [ pkgs.swaybg ];

            text = ''
              wallpaper=${assetsPath}/wallpaper-azura.jpg
              swaybg -i "$wallpaper" -m fill
            '';
          };
        in
        {
          ExecStart = lib.getExe' show "show-wallpaper";
          Restart = "on-failure";
        };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };

  home.packages = with pkgs; [
    libnotify
    wl-clipboard
    brightnessctl
    swaybg
    wl-clip-persist
    nautilus
    nautilus-open-any-terminal
  ];
}
