_: {
  flake.modules.nixos.sway =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.sway = {
        enable = true;
        package = pkgs.unstable.swayfx;
      };

      programs.uwsm = {
        enable = true;
        waylandCompositors = {
          sway = {
            prettyName = "Sway";
            comment = "Sway compositor managed by UWSM";
            binPath = "/run/current-system/sw/bin/sway";
            extraArgs = lib.optional (builtins.elem "nvidia" config.services.xserver.videoDrivers) "--unsupported-gpu";
          };
        };
      };

      services = {
        dbus.packages = [ pkgs.tumbler ];
        udisks2.enable = true;
        displayManager.defaultSession = lib.mkDefault "sway-uwsm";
      };

      systemd.user.targets."nixos-fake-graphical-session".enable = false;
    };

  flake.modules.homeManager.sway =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      confirmLogout = pkgs.writeShellApplication {
        name = "confirm-logout";
        runtimeInputs = [
          pkgs.libnotify
          pkgs.uwsm
        ];
        text = ''
          action="$(
            notify-send \
              --app-name=Sway \
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
      menu = "vicinae toggle";
      modifier = "Mod4";
      terminal = "${lib.getExe pkgs.uwsm} app -- ${lib.getExe pkgs.kitty}";
      wpctl = lib.getExe' pkgs.wireplumber "wpctl";
      swaymsg = lib.getExe' pkgs.unstable.swayfx "swaymsg";
      swaylock = lib.getExe config.programs.swaylock.package;
      vicinae = lib.getExe config.programs.vicinae.package;
      systemctl = lib.getExe' pkgs.systemd "systemctl";

      annotateScreenshot = pkgs.writeShellApplication {
        name = "screenshot-annotate";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.grim
          pkgs.satty
          pkgs.slurp
          pkgs.wl-clipboard
        ];
        text = ''
          geometry="$(slurp)" || exit 0
          dir="$HOME/Pictures/Screenshots"
          mkdir -p "$dir"
          grim -g "$geometry" - | satty \
            --filename - \
            --copy-command wl-copy \
            --actions-on-enter save-to-clipboard \
            --actions-on-escape exit \
            --output-filename "$dir/%Y%m%d_%H%M%S.png" \
            --early-exit
        '';
      };
    in
    {
      wayland.windowManager.sway = {
        enable = true;
        systemd.enable = false; # UWSM managed
        package = pkgs.unstable.swayfx;
        # SwayFX requires a DRM renderer even for its config check, which is unavailable in the build sandbox.
        checkConfig = false;
        wrapperFeatures.gtk = true;
        config = {
          defaultWorkspace = "workspace number 1";
          startup = [
            { command = "1password --silent"; }
            {
              command = "autotiling";
              always = true;
            }
          ];
          inherit menu modifier terminal;
          bars = [ ];
          gaps.smartBorders = "on";
          input = {
            "*".xkb_options = "ctrl:nocaps";
            "type:touchpad" = {
              dwt = "enabled";
              natural_scroll = "enabled";
              tap = "enabled";
            };
          };
          workspaceAutoBackAndForth = true;
          window = {
            titlebar = false;
            border = 1;
          };
          floating = {
            titlebar = false;
            criteria = [ { title = "^Authentication Required$"; } ];
          };
          focus.followMouse = false;
          keybindings =
            removeAttrs
              (lib.mkOptionDefault {
                "${modifier}+q" = "exec ${terminal}";
                "${modifier}+c" = "kill";
                "${modifier}+space" = "exec ${menu}";
                "${modifier}+Alt+Space" = "focus mode_toggle";
                "${modifier}+Escape" = "exec swaylock";
                "${modifier}+Shift+e" = "exec ${lib.getExe confirmLogout}";
                "${modifier}+Shift+s" = "exec grimshot copy anything";
                "${modifier}+Shift+a" = "exec ${lib.getExe annotateScreenshot}";
                "${modifier}+v" = "exec ${vicinae} deeplink 'vicinae://launch/clipboard/history'";
                "XF86AudioLowerVolume" = "exec ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
                "XF86AudioMicMute" = "exec ${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
                "XF86AudioMute" = "exec ${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
                "XF86AudioRaiseVolume" = "exec ${wpctl} set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
                "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
                "XF86MonBrightnessUp" = "exec brightnessctl set 5%+";
              })
              [
                "${modifier}+Return"
                "${modifier}+Shift+q"
                "${modifier}+d"
              ];
        };
        extraConfig = ''
          bindgesture swipe:3:right workspace prev
          bindgesture swipe:3:left workspace next
          seat * hide_cursor when-typing enable
          blur enable
          default_dim_inactive 0.1
          for_window [app_id="com.gabm.satty"] floating enable
          exec uwsm finalize
        '';
      };

      programs.swaylock.enable = true;

      services.swayidle = {
        enable = true;
        events = {
          before-sleep = "${swaylock} -f";
          after-resume = "${swaymsg} 'output * dpms on'";
        };
        timeouts = [
          {
            timeout = 300;
            command = "${swaylock} -f";
          }
          {
            timeout = 600;
            command = "${swaymsg} 'output * dpms off'";
            resumeCommand = "${swaymsg} 'output * dpms on'";
          }
          {
            timeout = 1800;
            command = "${systemctl} suspend-then-hibernate";
          }
        ];
      };

      programs.gpg.enable = true;

      services.gpg-agent = {
        enable = true;
        pinentry.package = pkgs.pinentry-gnome3;
      };

      home.packages = with pkgs; [
        brightnessctl
        wl-clipboard
        sway-contrib.grimshot
        grim
        slurp
        satty
        atril
        ristretto
        seahorse
        thunar
        tumbler
        xarchiver
        xfce4-screenshooter
        autotiling
        wdisplays
      ];

      home.sessionVariables = {
        "NIXOS_OZONE_WL" = "1";
        "ELECTRON_OZONE_PLATFORM_HINT" = "auto";
      };

      systemd.user.services.sway-polkit-agent = {
        Unit = {
          Description = "LXQt PolicyKit Authentication Agent for Sway";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
          ConditionEnvironment = "XDG_SESSION_DESKTOP=sway";
        };
        Service = {
          ExecStart = "${lib.getExe pkgs.lxqt.lxqt-policykit}";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      services = {
        mako.enable = true;
        udiskie.enable = true;
      };

      systemd.user.services = {
        mako.Unit.ConditionEnvironment = "XDG_SESSION_DESKTOP=sway";
        udiskie.Unit.ConditionEnvironment = "XDG_SESSION_DESKTOP=sway";
        swayidle.Unit.ConditionEnvironment = lib.mkForce [
          "WAYLAND_DISPLAY"
          "XDG_SESSION_DESKTOP=sway"
        ];
        waybar.Unit.ConditionEnvironment = lib.mkForce [
          "WAYLAND_DISPLAY"
          "XDG_SESSION_DESKTOP=sway"
        ];
      };
    };
}
