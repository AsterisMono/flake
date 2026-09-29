{ inputs, ... }:
{
  flake-file.inputs.niri = {
    url = "github:sodiboo/niri-flake";
  };

  flake.modules.nixos.niri =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.niri.nixosModules.niri ];

      programs.niri = {
        enable = true;
        # niri-flake's settings module is generated from its own niri-unstable
        # revision, and the flake caches that build for both release lines.
        package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
      };

      services.displayManager.defaultSession = lib.mkDefault "niri";

      services.dbus.packages = [ pkgs.tumbler ];

      # Noctalia provides its own polkit agent.
      systemd.user.services.niri-flake-polkit.enable = false;
    };

  flake.modules.homeManager.niri =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      kitty = lib.getExe pkgs.kitty;
      noctalia-msg =
        args:
        [
          (lib.getExe osConfig.programs.noctalia.package)
          "msg"
        ]
        ++ args;
    in
    {
      programs.niri.settings = {
        binds = {
          # niri's default bindings, with this desktop's overrides: Mod+Shift
          # moves the focused column or window and Mod+Ctrl focuses a monitor
          # (niri has those the other way around), center-column sits on Mod+Z
          # because Mod+C closes a window, and the launcher, clipboard,
          # screenshots, and audio and brightness keys go through Noctalia.
          # Mod+T (alacritty) and the swaylock and orca binds are intentionally
          # absent because those programs are not installed.

          "Mod+O" = {
            repeat = false;
            action.toggle-overview = [ ];
          };

          "Mod+H".action.focus-column-left = [ ];
          "Mod+J".action.focus-window-down = [ ];
          "Mod+K".action.focus-window-up = [ ];
          "Mod+L".action.focus-column-right = [ ];

          "Mod+Shift+H".action.move-column-left = [ ];
          "Mod+Shift+J".action.move-window-down = [ ];
          "Mod+Shift+K".action.move-window-up = [ ];
          "Mod+Shift+L".action.move-column-right = [ ];

          "Mod+Ctrl+H".action.focus-monitor-left = [ ];
          "Mod+Ctrl+J".action.focus-monitor-down = [ ];
          "Mod+Ctrl+K".action.focus-monitor-up = [ ];
          "Mod+Ctrl+L".action.focus-monitor-right = [ ];

          "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = [ ];
          "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = [ ];
          "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = [ ];
          "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = [ ];

          "Mod+Home".action.focus-column-first = [ ];
          "Mod+End".action.focus-column-last = [ ];
          "Mod+Ctrl+Home".action.move-column-to-first = [ ];
          "Mod+Ctrl+End".action.move-column-to-last = [ ];

          "Mod+U".action.focus-workspace-down = [ ];
          "Mod+I".action.focus-workspace-up = [ ];
          "Mod+Ctrl+U".action.move-column-to-workspace-down = [ ];
          "Mod+Ctrl+I".action.move-column-to-workspace-up = [ ];
          "Mod+Shift+U".action.move-workspace-down = [ ];
          "Mod+Shift+I".action.move-workspace-up = [ ];
          "Mod+Tab".action.focus-workspace-previous = [ ];

          "Mod+WheelScrollDown" = {
            cooldown-ms = 150;
            action.focus-workspace-down = [ ];
          };
          "Mod+WheelScrollUp" = {
            cooldown-ms = 150;
            action.focus-workspace-up = [ ];
          };
          "Mod+Ctrl+WheelScrollDown" = {
            cooldown-ms = 150;
            action.move-column-to-workspace-down = [ ];
          };
          "Mod+Ctrl+WheelScrollUp" = {
            cooldown-ms = 150;
            action.move-column-to-workspace-up = [ ];
          };
          "Mod+WheelScrollRight".action.focus-column-right = [ ];
          "Mod+WheelScrollLeft".action.focus-column-left = [ ];
          "Mod+Ctrl+WheelScrollRight".action.move-column-right = [ ];
          "Mod+Ctrl+WheelScrollLeft".action.move-column-left = [ ];
          "Mod+Shift+WheelScrollDown".action.focus-column-right = [ ];
          "Mod+Shift+WheelScrollUp".action.focus-column-left = [ ];
          "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = [ ];
          "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = [ ];

          "Mod+1".action.focus-workspace = 1;
          "Mod+2".action.focus-workspace = 2;
          "Mod+3".action.focus-workspace = 3;
          "Mod+4".action.focus-workspace = 4;
          "Mod+5".action.focus-workspace = 5;
          "Mod+6".action.focus-workspace = 6;
          "Mod+7".action.focus-workspace = 7;
          "Mod+8".action.focus-workspace = 8;
          "Mod+9".action.focus-workspace = 9;
          "Mod+Shift+1".action.move-column-to-workspace = 1;
          "Mod+Shift+2".action.move-column-to-workspace = 2;
          "Mod+Shift+3".action.move-column-to-workspace = 3;
          "Mod+Shift+4".action.move-column-to-workspace = 4;
          "Mod+Shift+5".action.move-column-to-workspace = 5;
          "Mod+Shift+6".action.move-column-to-workspace = 6;
          "Mod+Shift+7".action.move-column-to-workspace = 7;
          "Mod+Shift+8".action.move-column-to-workspace = 8;
          "Mod+Shift+9".action.move-column-to-workspace = 9;

          "Mod+BracketLeft".action.consume-or-expel-window-left = [ ];
          "Mod+BracketRight".action.consume-or-expel-window-right = [ ];
          "Mod+Comma".action.consume-window-into-column = [ ];
          "Mod+Period".action.expel-window-from-column = [ ];

          "Mod+R".action.switch-preset-column-width = [ ];
          "Mod+Shift+R".action.switch-preset-column-width-back = [ ];
          "Mod+Ctrl+Shift+R".action.switch-preset-window-height = [ ];
          "Mod+Ctrl+R".action.reset-window-height = [ ];

          "Mod+F".action.maximize-column = [ ];
          "Mod+Shift+F".action.fullscreen-window = [ ];
          "Mod+M".action.maximize-window-to-edges = [ ];
          "Mod+Ctrl+F".action.expand-column-to-available-width = [ ];
          "Mod+Z".action.center-column = [ ];
          "Mod+Shift+Z".action.center-visible-columns = [ ];

          "Mod+Minus".action.set-column-width = "-10%";
          "Mod+Equal".action.set-column-width = "+10%";
          "Mod+Shift+Minus".action.set-window-height = "-10%";
          "Mod+Shift+Equal".action.set-window-height = "+10%";

          "Mod+Backslash".action.switch-focus-between-floating-and-tiling = [ ];
          "Mod+Shift+Backslash".action.toggle-window-floating = [ ];
          "Mod+W".action.toggle-column-tabbed-display = [ ];

          "Mod+Escape" = {
            allow-inhibiting = false;
            action.spawn = noctalia-msg [
              "session"
              "lock"
            ];
          };
          "Mod+Shift+Escape".action.power-off-monitors = [ ];
          "Mod+Shift+E".action.quit = [ ];
          "Mod+Shift+P".action.spawn = noctalia-msg [ "screenshot-fullscreen" ];

          # Sway's custom bindings carried over, plus the launcher. Noctalia
          # provides the launcher, clipboard, and screenshot UI.
          "Mod+Q".action.spawn = kitty;
          "Mod+C".action.close-window = [ ];
          "Mod+D".action.spawn = noctalia-msg [
            "panel-toggle"
            "launcher"
          ];
          "Mod+V".action.spawn = noctalia-msg [
            "panel-toggle"
            "clipboard"
          ];
          "Mod+Shift+S".action.spawn = noctalia-msg [ "screenshot-region" ];
          "Mod+Shift+A".action.spawn = noctalia-msg [ "screenshot-annotate" ];

          "XF86AudioRaiseVolume" = {
            allow-when-locked = true;
            action.spawn = noctalia-msg [ "volume-up" ];
          };
          "XF86AudioLowerVolume" = {
            allow-when-locked = true;
            action.spawn = noctalia-msg [ "volume-down" ];
          };
          "XF86AudioMute" = {
            allow-when-locked = true;
            action.spawn = noctalia-msg [ "volume-mute" ];
          };
          "XF86AudioMicMute" = {
            allow-when-locked = true;
            action.spawn = noctalia-msg [ "mic-mute" ];
          };
          "XF86AudioPlay" = {
            allow-when-locked = true;
            action.spawn = noctalia-msg [
              "media"
              "toggle"
            ];
          };
          "XF86AudioStop" = {
            allow-when-locked = true;
            action.spawn = noctalia-msg [
              "media"
              "stop"
            ];
          };
          "XF86AudioPrev" = {
            allow-when-locked = true;
            action.spawn = noctalia-msg [
              "media"
              "previous"
            ];
          };
          "XF86AudioNext" = {
            allow-when-locked = true;
            action.spawn = noctalia-msg [
              "media"
              "next"
            ];
          };
          "XF86MonBrightnessUp" = {
            allow-when-locked = true;
            action.spawn = noctalia-msg [ "brightness-up" ];
          };
          "XF86MonBrightnessDown" = {
            allow-when-locked = true;
            action.spawn = noctalia-msg [ "brightness-down" ];
          };
        };

        input = {
          keyboard = {
            xkb.options = "ctrl:nocaps";
            # Fcitx5 keeps its state per window rather than globally.
            track-layout = "window";
          };
          touchpad = {
            dwt = true;
            natural-scroll = true;
            tap = true;
            drag-lock = true;
            disabled-on-external-mouse = true;
          };
          workspace-auto-back-and-forth = true;
        };

        layout = {
          # Keep window gaps level with the corner radius; niri's 16 px default
          # is wider than this shell's surfaces.
          gaps = 12.0;
          # niri-flake defaults to "windows decide", which lets two columns add
          # up wider than the screen; niri's own default splits it in half.
          default-column-width = {
            proportion = 0.5;
          };
          # Noctalia's wallpaper layer is placed in the backdrop below.
          background-color = "transparent";
          # The border keeps its themed Stylix colours and is the only focus
          # indicator.
          focus-ring.enable = false;
          border.width = 2.0;
        };

        cursor.hide-when-typing = true;
        prefer-no-csd = true;

        # Keep the overview flat; the backdrop is enough.
        overview.workspace-shadow.enable = false;

        # The desktop shell owns the important hotkeys now; do not advertise
        # unbound actions at startup.
        hotkey-overlay = {
          skip-at-startup = true;
          hide-not-bound = true;
        };

        switch-events.lid-close.action.spawn = noctalia-msg [
          "session"
          "lock-and-suspend"
        ];

        # niri-flake enables XWayland integration by default but installs no
        # binary; point it at the package.
        xwayland-satellite.path = lib.getExe pkgs.unstable.xwayland-satellite;

        spawn-at-startup = [
          {
            argv = [
              "1password"
              "--silent"
            ];
          }
        ];

        # Noctalia needs this to raise windows for notification actions.
        debug.honor-xdg-activation-with-invalid-serial = [ ];

        window-rules = [
          {
            geometry-corner-radius = {
              top-left = 8.0;
              top-right = 8.0;
              bottom-right = 8.0;
              bottom-left = 8.0;
            };
            clip-to-geometry = true;
          }
          {
            matches = [ { title = "^Authentication Required$"; } ];
            open-floating = true;
          }
          {
            # Telegram opens its media viewer as a second toplevel from the
            # same process as the chat window.
            matches = [
              {
                app-id = "^org\\.telegram\\.desktop$";
                title = "(?i)^(媒体查看器|media viewer)$";
              }
            ];
            open-floating = true;
          }
          {
            matches = [ { app-id = "dev.noctalia.Noctalia"; } ];
            open-floating = true;
            default-column-width = {
              fixed = 1080;
            };
            default-window-height = {
              fixed = 920;
            };
          }
          {
            # Keep 1Password out of every capture path.
            matches = [ { app-id = "(?i)1password"; } ];
            block-out-from = "screen-capture";
          }
          {
            # On-demand VRR reaches these while they sit on an output that
            # offers it.
            matches = [
              { app-id = "^steam$"; }
              { app-id = "^steam_app_"; }
              { app-id = "^gamescope$"; }
              { app-id = "^mpv$"; }
            ];
            variable-refresh-rate = true;
          }
        ];

        # https://docs.noctalia.dev/noctalia/compositor-settings/niri/
        layer-rules = [
          {
            matches = [
              { namespace = "^noctalia-backdrop"; }
            ];
            place-within-backdrop = true;
          }
        ];
      };

      # niri-flake's settings schema does not expose background effects yet, so
      # append a KDL document to the settings-rendered one. The rendered
      # document enters as an option default (priority 1500), so this must use
      # the same priority to be merged with it instead of replacing it. Kitty
      # is semitransparent from Stylix and only speaks the KDE blur protocol,
      # which niri does not implement, so niri blurs its background here.
      programs.niri.config = lib.mkOptionDefault [
        (inputs.niri.lib.kdl.node "window-rule"
          [ ]
          [
            (inputs.niri.lib.kdl.leaf "match" { app-id = "^kitty$"; })
            (inputs.niri.lib.kdl.leaf "match" {
              app-id = "^(firefox|org\\.mozilla\\.firefox)$";
            })
            # Both windows use client-side decorations, so without this niri
            # paints the border as a solid rectangle behind them, which shows
            # through their transparency as a glow.
            (inputs.niri.lib.kdl.leaf "draw-border-with-background" false)
            (inputs.niri.lib.kdl.node "background-effect"
              [ ]
              [
                (inputs.niri.lib.kdl.leaf "blur" true)
                (inputs.niri.lib.kdl.leaf "xray" false)
              ]
            )
          ]
        )
      ];

      home = {
        packages = with pkgs; [
          atril
          brightnessctl
          ristretto
          seahorse
          thunar
          tumbler
          wl-clipboard
          xarchiver
        ];

        sessionVariables = {
          "NIXOS_OZONE_WL" = "1";
          "ELECTRON_OZONE_PLATFORM_HINT" = "auto";
        };
      };

      programs.gpg.enable = true;

      services.gpg-agent = {
        enable = true;
        pinentry.package = pkgs.pinentry-gnome3;
      };
    };
}
