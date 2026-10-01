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
            }
            {
              name = "video-vrr";
              match.class = "^mpv$";
              content = "video";
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
