_: {
  flake.modules.nixos.hyprland =
    { lib, pkgs, ... }:
    {
      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };

      services.displayManager.defaultSession = lib.mkDefault "hyprland-uwsm";
      services.dbus.packages = [ pkgs.tumbler ];

      # The compositor asks Noctalia to lock before suspending on lid close.
      services.logind.settings.Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
      };

      # UWSM owns the graphical session and Noctalia supplies the polkit agent.
      systemd.user.targets.nixos-fake-graphical-session.enable = false;
    };

  flake.modules.homeManager.hyprland =
    {
      config,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      toLua = lib.generators.toLua { };
      uwsm = lib.getExe pkgs.uwsm;
      confirmLogout = pkgs.writeShellApplication {
        name = "confirm-logout";
        runtimeInputs = [
          pkgs.libnotify
          pkgs.uwsm
        ];
        text = ''
          action="$(
            notify-send \
              --app-name=Hyprland \
              --urgency=critical \
              --expire-time=10000 \
              --action=default="Log out" \
              --wait \
              "Log out?" \
              "Left-click to end the Wayland session"
          )"

          if [[ "$action" == "default" ]]; then
            uwsm stop
          fi
        '';
      };
    in
    {
      wayland.windowManager.hyprland = {
        enable = true;
        configType = "lua";
        package = null;
        portalPackage = null;
        systemd.enable = false; # UWSM manages the session, including Noctalia.

        settings = {
          monitor = [
            {
              output = "";
              mode = "preferred";
              position = "auto";
              scale = "auto";
            }
          ];

          config = {
            general = {
              layout = "dwindle";
              # Each adjacent window contributes gaps_in to the shared gap.
              gaps_in = 6;
              gaps_out = 12;
              border_size = 2;
              resize_on_border = true;
              snap.enabled = true;
            };
            dwindle = {
              # Like Sway autotiling, split the focused window along its
              # longer dimension; pointer position does not choose the axis.
              smart_split = false;
              split_width_multiplier = 1.0;
              preserve_split = false;
              use_active_for_splits = true;
              force_split = 2;
            };
            decoration = {
              rounding = 8;
              blur = {
                enabled = true;
                size = 3;
                passes = 2;
                xray = false;
              };
            };
            input = {
              kb_options = "ctrl:nocaps";
              follow_mouse = 0;
              focus_on_close = 2;
              touchpad = {
                disable_while_typing = true;
                natural_scroll = true;
                tap_to_click = true;
                drag_lock = true;
              };
            };
            cursor.hide_on_key_press = true;
            binds = {
              workspace_back_and_forth = true;
              allow_workspace_cycles = true;
              movefocus_cycles_groupfirst = true;
            };
            misc = {
              disable_hyprland_logo = true;
              force_default_wallpaper = 0;
              # Noctalia notification actions may raise their target window.
              focus_on_activate = true;
              # Fullscreen and content-type video/game windows can use VRR.
              vrr = 3;
            };
          };

          curve = [
            # HyDE's macOS preset, with its default duration scale of 1.
            # https://github.com/HyDE-Project/HyDE/blob/master/Configs/.local/share/hypr/lua/animations/macos.lua
            {
              _args = [
                "macOpen"
                {
                  type = "spring";
                  mass = 1;
                  stiffness = 110;
                  dampening = 16;
                }
              ];
            }
            {
              _args = [
                "macBounce"
                {
                  type = "spring";
                  mass = 1;
                  stiffness = 80;
                  dampening = 10;
                }
              ];
            }
            {
              _args = [
                "macSmooth"
                {
                  type = "bezier";
                  points = [
                    [
                      0.25
                      0.1
                    ]
                    [
                      0.25
                      1.0
                    ]
                  ];
                }
              ];
            }
          ];

          animation = [
            {
              leaf = "global";
              enabled = true;
              speed = 8; # 800 ms, also matching the built-in fallback.
              bezier = "default";
            }
            # Spring timing ignores speed; keep the preset's API values.
            {
              leaf = "windows";
              enabled = true;
              speed = 8;
              spring = "macOpen";
              style = "popin 90%";
            }
            {
              leaf = "windowsIn";
              enabled = true;
              speed = 8;
              spring = "macOpen";
              style = "popin 90%";
            }
            {
              leaf = "windowsOut";
              enabled = true;
              speed = 7;
              spring = "macBounce";
              style = "popin 90%";
            }
            {
              leaf = "windowsMove";
              enabled = true;
              speed = 5;
              bezier = "macSmooth";
              style = "slide";
            }
            {
              leaf = "fade";
              enabled = true;
              speed = 8;
              bezier = "default";
            }
            {
              leaf = "workspaces";
              enabled = true;
              speed = 6;
              bezier = "macSmooth";
              style = "slidefade 20%";
            }
            {
              leaf = "border";
              enabled = true;
              speed = 1;
              bezier = "default";
            }
            {
              leaf = "borderangle";
              enabled = true;
              speed = 30;
              bezier = "default";
              style = "once";
            }
            {
              leaf = "zoomFactor";
              enabled = true;
              speed = 7;
              bezier = "default";
            }
            {
              leaf = "monitorAdded";
              enabled = true;
              speed = 7;
              bezier = "default";
            }
          ];

          window_rule = [
            {
              name = "authentication";
              match.title = "^Authentication Required$";
              float = true;
            }
            {
              name = "telegram-media";
              match = {
                class = "^org\\.telegram\\.desktop$";
                title = "(?i)^(媒体查看器|media viewer)$";
              };
              float = true;
            }
            {
              name = "firefox-picture-in-picture";
              match = {
                class = "(?i)^(firefox|org[.]mozilla[.]firefox)$";
                title = "^(Picture-in-Picture|画中画)$";
              };
              float = true;
              pin = true;
              keep_aspect_ratio = true;
              persistent_size = true;
            }
            {
              name = "meeting-idle-inhibit";
              match.class = "(?i)^(wemeet(app)?|com[.]tencent[.]wemeet)$";
              # A focused meeting window inhibits idle; a background client
              # alone must not prevent the laptop from suspending forever.
              idle_inhibit = "focus";
            }
            {
              name = "noctalia-settings";
              match.class = "^dev\\.noctalia\\.Noctalia$";
              float = true;
              size = [
                1080
                920
              ];
              center = true;
            }
            {
              name = "1password-capture";
              match.class = "(?i).*1password.*";
              no_screen_share = true;
            }
            {
              name = "gaming-vrr";
              match.class = "^(steam|steam_app_.*|gamescope)$";
              content = "game";
              idle_inhibit = "fullscreen";
            }
            {
              name = "video-vrr";
              match.class = "^mpv$";
              content = "video";
              idle_inhibit = "fullscreen";
            }
          ];

          # https://docs.noctalia.dev/noctalia/compositor-settings/hyprland/
          layer_rule = [
            {
              name = "noctalia";
              match.namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$";
              no_anim = true;
              ignore_alpha = 0.5;
              blur = true;
              blur_popups = true;
            }
            {
              name = "noctalia-notification-privacy";
              match.namespace = "^noctalia-notification$";
              no_screen_share = true;
            }
          ];

          gesture = {
            fingers = 3;
            direction = "horizontal";
            action = "workspace";
          };
          on._args = [
            "hyprland.start"
            (lib.generators.mkLuaInline ''
              function()
                hl.exec_cmd(${toLua "${uwsm} app -- 1password --silent"})
              end
            '')
          ];
        };

        extraConfig =
          builtins.replaceStrings
            [ "@terminal@" "@ipc@" "@logout@" "@reload@" ]
            [
              (toLua "${uwsm} app -- ${lib.getExe pkgs.kitty}")
              (toLua "${lib.getExe osConfig.programs.noctalia.package} msg ")
              (toLua (lib.getExe confirmLogout))
              (toLua "${lib.getExe' osConfig.programs.hyprland.package "hyprctl"} reload config-only")
            ]
            (builtins.readFile ./bindings.lua);
      };

      # Noctalia owns wallpaper rendering; a second wallpaper daemon would
      # compete with its per-monitor wallpaper settings.
      stylix.targets.hyprland.hyprpaper.enable = false;
      xdg.configFile."uwsm/env".source =
        "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
      xdg.configFile."hypr/xdph.conf".text = ''
        screencopy {
          max_fps = 60
        }
      '';

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
          NIXOS_OZONE_WL = "1";
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
        };
      };

      programs.gpg.enable = true;
      services.gpg-agent = {
        enable = true;
        pinentry.package = pkgs.pinentry-gnome3;
      };
    };
}
