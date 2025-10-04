{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:
# https://github.com/jetjinser/flake/blob/master/hosts/dorothy/desktop/niri.nix
# https://github.com/ryan4yin/nix-config/tree/main/home/linux/gui/niri
# Thank you jinser & ryan4yin!
{
  imports = [ ./waybar ];

  programs.niri =
    let
      fuzzelScripts = ./fuzzelScripts;
      monitors = {
        gpd = "Japan Display Inc. GPD1001H 0x00000001";
        superwide = "Beihai Century Joint Innovation Technology Co.,Ltd C34SKN Unknown";
        npc = "PNP(XYA) NPC Xianyou 0x00000003";
      };
    in
    {
      package = pkgs.niri-stable;

      settings = {
        spawn-at-startup = [
          { command = [ "firefox" ]; }
          { command = [ "Telegram" ]; }
          { command = [ "bitwarden" ]; }
        ]
        ++ lib.optionals (hostname == "aeris") [
          { command = lib.strings.splitString " " "kitty --class sysmon btop"; }
        ]
        ++ lib.optionals (hostname == "zephira") [
          { command = [ "bytedance-feishu" ]; }
          { command = [ "spotify" ]; }
        ];

        hotkey-overlay.skip-at-startup = true;
        prefer-no-csd = true;
        xwayland-satellite.path = "${lib.getExe pkgs.xwayland-satellite-stable}";

        outputs = {
          "${monitors.superwide}" = {
            scale = 1;
            mode = {
              width = 3440;
              height = 1440;
              refresh = 120.000;
            };
            position.x = 0;
            position.y = 0;
            focus-at-startup = true;
          };
          "${monitors.gpd}" = {
            scale = 1.5;
            position.x = 3440;
            position.y = 0;
          };
          "${monitors.npc}" = {
            mode = {
              width = 2560;
              height = 1440;
              refresh = 75.000;
            };
          };
        };

        layout = {
          default-column-width.proportion = 0.5;
          # https://github.com/YaLTeR/niri/wiki/Overview#backdrop-customization
          background-color = "transparent";
          always-center-single-column = true;
          center-focused-column = "on-overflow";
          border.width = 2;
          struts.top = -16;
        };

        cursor.hide-when-typing = true;

        binds =
          with config.lib.niri.actions;
          let
            sh = spawn "sh" "-c";
            wpctl = lib.getExe' pkgs.wireplumber "wpctl";
            playerctl = lib.getExe' pkgs.playerctl "playerctl";
          in
          {
            "Mod+D".action = spawn "fuzzel";
            "Mod+Q".action = spawn "kitty";
            "Mod+Shift+Q".action =
              sh "kitty --detach && sleep 0.2 && niri msg action consume-or-expel-window-left";
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

            "Mod+Shift+Ctrl+H".action = move-column-to-monitor-left;
            "Mod+Shift+Ctrl+J".action = move-column-to-monitor-down;
            "Mod+Shift+Ctrl+K".action = move-column-to-monitor-up;
            "Mod+Shift+Ctrl+L".action = move-column-to-monitor-right;

            "Mod+U".action = focus-workspace-down;
            "Mod+I".action = focus-workspace-up;
            "Mod+Shift+U".action = move-column-to-workspace-down;
            "Mod+Shift+I".action = move-column-to-workspace-up;
            "Mod+WheelScrollDown" = {
              action = focus-workspace-down;
              cooldown-ms = 150;
            };
            "Mod+WheelScrollUp" = {
              action = focus-workspace-up;
              cooldown-ms = 150;
            };
            "Mod+Ctrl+WheelScrollDown" = {
              action = move-column-to-workspace-down;
              cooldown-ms = 150;
            };
            "Mod+Ctrl+WheelScrollUp" = {
              action = move-column-to-workspace-up;
              cooldown-ms = 150;
            };
            "Mod+Shift+WheelScrollDown".action = focus-column-right;
            "Mod+Shift+WheelScrollUp".action = focus-column-left;
            "Mod+Ctrl+Shift+WheelScrollDown".action = move-column-right;
            "Mod+Ctrl+Shift+WheelScrollUp".action = move-column-left;

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
            "Mod+Shift+Minus".action = set-window-height "-10%";
            "Mod+Shift+Equal".action = set-window-height "+10%";

            "Mod+Shift+V".action = toggle-window-floating;
            "Mod+Alt+Shift+V".action = switch-focus-between-floating-and-tiling;

            "Mod+Shift+S".action = screenshot;
            "Mod+Shift+W".action = screenshot-window;
            # https://github.com/sodiboo/niri-flake/issues/922
            "Mod+Shift+P".action.screenshot-screen = [ ];

            "Mod+1".action = focus-workspace "workpad";
            "Mod+2".action = focus-workspace "messengers";
            "Mod+3".action = focus-workspace "spotify";
            "Mod+0".action = focus-workspace "tray";

            "Mod+M".action = sh "makoctl dismiss --all";
            "Mod+W".action = toggle-column-tabbed-display;

            "Mod+V".action =
              let
                fuzzel-cliphist = pkgs.writeShellApplication {
                  name = "fuzzel-cliphist";
                  runtimeInputs = with pkgs; [
                    cliphist
                    imagemagick
                    fuzzel
                    gawk
                  ];
                  bashOptions = [
                    "nounset"
                    "pipefail"
                  ];
                  text = builtins.readFile "${fuzzelScripts}/cliphist.sh";
                };
              in
              sh (lib.getExe fuzzel-cliphist);

            "Mod+P".action =
              let
                fuzzel-projects = pkgs.writeShellApplication {
                  name = "fuzzel-projects";
                  runtimeInputs = with pkgs; [
                    fuzzel
                    libnotify
                  ];
                  bashOptions = [
                    "nounset"
                    "pipefail"
                  ];
                  text = builtins.readFile "${fuzzelScripts}/projects.sh";
                };
              in
              sh (lib.getExe fuzzel-projects);

            "Mod+Shift+E".action = quit;

            "XF86AudioRaiseVolume" = {
              action = sh "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%+";
              allow-when-locked = true;
            };
            "XF86AudioLowerVolume" = {
              action = sh "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
              allow-when-locked = true;
            };
            "Ctrl+Mod+Left" = {
              action = sh "${playerctl} previous";
              allow-when-locked = true;
            };
            "Ctrl+Mod+Right" = {
              action = sh "${playerctl} next";
              allow-when-locked = true;
            };
            "Ctrl+Mod+Space" = {
              action = sh "${playerctl} play-pause";
              allow-when-locked = true;
            };
            "XF86AudioMute" = {
              action = sh "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
              allow-when-locked = true;
            };
            "XF86MonBrightnessUp".action = sh "brightnessctl s 5%+";
            "XF86MonBrightnessDown".action = sh "brightnessctl s 5%-";

            "Ctrl+Mod+Delete".action = sh (lib.getExe pkgs.swaylock-effects);
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
              {
                app-id = "^com\.network\.manager$";
              }
            ];
            open-floating = true;
            default-window-height.proportion = 0.65;
            default-column-width.proportion = 0.25;
          }
          {
            matches = [
              {
                app-id = "^org\.gnome\.Nautilus$";
              }
            ];
            open-floating = true;
            default-window-height.proportion = 0.65;
            default-column-width.proportion = 0.4;
          }
          {
            matches = [
              { app-id = "^Bitwarden$"; }
            ];
            open-on-workspace = "tray";
            default-column-width.proportion = 0.5;
          }
          {
            matches = [
              { app-id = "^sysmon$"; }
            ];
            open-on-workspace = "tray";
            default-column-width.proportion = 1.0;
          }
          {
            matches = [
              { app-id = "^spotify$"; }
              { app-id = "^com\.gitee\.gmg137\.NeteaseCloudMusicGtk4$"; }
            ];
            open-on-workspace = "spotify";
            default-column-width.proportion = 0.66667;
          }
          {
            matches = builtins.map (l: l // { at-startup = true; }) [
              { app-id = "^firefox$"; }
              { app-id = "^org\.telegram\.desktop$"; }
              { app-id = "^Bytedance-feishu$"; }
              { app-id = "^spotify$"; }
              { app-id = "^sysmon$"; }
              { app-id = "^Bitwarden$"; }
              { app-id = "^QQ$"; }
            ];
            open-focused = false;
          }
        ];

        workspaces = {
          "01-workpad" = {
            name = "workpad";
            open-on-output = monitors.superwide;
          };
          "02-messengers" = {
            name = "messengers";
            open-on-output = monitors.superwide;
          };
          "03-spotify" = {
            name = "spotify";
            open-on-output = monitors.superwide;
          };
          "99-tray" = {
            name = "tray";
            open-on-output = monitors.gpd;
          };
        };
      };
    };

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        icon-theme = "Tela-light";
        terminal = "${lib.getExe pkgs.kitty}";
      };
    };
  };

  programs.kitty = {
    enable = true;
    settings = {
      font_size = lib.mkForce 11.0;
      cursor_shape = "beam";
      cursor_blink_interval = 0;
      cursor_beam_thickness = 1.2;
      allow_remote_control = "socket-only";
      listen_on = "unix:/tmp/kitty";
      shell_integration = "enabled";
    };
    extraConfig = ''
      # kitty-scrollback.nvim Kitten alias
      action_alias kitty_scrollback_nvim kitten /home/cmiki/.local/share/nvim/lazy/kitty-scrollback.nvim/python/kitty_scrollback_nvim.py
      # Browse scrollback buffer in nvim
      map kitty_mod+h kitty_scrollback_nvim
      # Browse output of the last shell command in nvim
      map kitty_mod+g kitty_scrollback_nvim --config ksb_builtin_last_cmd_output
      # Show clicked command output in nvim
      mouse_map ctrl+shift+right press ungrabbed combine : mouse_select_command_output : kitty_scrollback_nvim --config ksb_builtin_last_visited_cmd_output
    '';
  };

  services.mako.enable = true;

  # Wallpaper
  services.swww.enable = true;

  systemd.user.services =
    let
      wallpaper = config.stylix.image;
      blurredWallpaper = pkgs.runCommand "wallpaper-blurred" { } ''
        ${lib.getExe' pkgs.imagemagick "magick"} ${wallpaper} -blur 0x32 $out
      '';
    in
    {
      # Swaybg: blurred overview
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
              name = "swaybg-show-wallpaper";

              text = ''
                ${lib.getExe pkgs.swaybg} -i "${blurredWallpaper}" -m fill
              '';
            };
          in
          {
            ExecStart = lib.getExe show;
            Restart = "on-failure";
          };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      # swww: workspace wallpaper
      swww-instance = {
        Unit = {
          Description = "swww - show wallpaper";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
          Requisite = [ "graphical-session.target" ];
        };
        Service =
          let
            show = pkgs.writeShellApplication {
              name = "swww-show-wallpaper";

              text = ''
                ${lib.getExe pkgs.swww} img ${wallpaper}
              '';
            };
          in
          {
            ExecStart = lib.getExe show;
            Type = "oneshot";
          };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };

  services.cliphist = {
    enable = true;
    allowImages = true;
  };

  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      daemonize = true;
      clock = true;
      timestr = "%k:%M";
      datestr = "%Y-%m-%d";
      show-failed-attempts = true;
      indicator = true;
      screenshots = true;
      effect-blur = "5x5";
    };
  };

  services.swayidle =
    let
      swaylock = lib.getExe pkgs.swaylock-effects;
    in
    {
      enable = true;
      events = [
        {
          event = "before-sleep";
          command = swaylock;
        }
        {
          event = "lock";
          command = swaylock;
        }
      ];
      timeouts = [
        {
          timeout = 600;
          command = swaylock;
        }
      ];
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
