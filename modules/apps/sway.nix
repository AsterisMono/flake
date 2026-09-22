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
      vicinae = lib.getExe config.programs.vicinae.package;

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
                "${modifier}+Escape" = "exec ${lib.getExe config.programs.swaylock.package}";
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
          # SwayFX defaults to three blur passes. Each pass samples further past
          # the edge of the surface being blurred, and at an output border that
          # reach pulls neighbouring framebuffer content into the panel, showing
          # up as a band as wide as the blur radius along the panel's edge. Two
          # passes stay inside the surface and look the same.
          blur_passes 2
          # Bars never have a window behind them: tiled windows stop at the
          # exclusive zone. Blurring the wallpaper is what gives them the same
          # frosted material as the popups, which blur whatever is behind them.
          layer_effects "quickshell-bar-top" {
            blur enable
            blur_xray enable
            # Without this the blur is also painted over the surface's
            # transparent pixels, which at fractional scale adds one device
            # pixel of blurred wallpaper below the bar and over the window
            # under it.
            blur_ignore_transparent enable
          }
          layer_effects "quickshell-bar-bottom" {
            blur enable
            blur_xray enable
            blur_ignore_transparent enable
          }
          layer_effects "quickshell-popup" {
            blur enable
            # SwayFX's default shadow (50% black, 20 px blur) reads as a heavy
            # halo around a panel this large. A wider, much fainter shadow keeps
            # the panel lifted without the glow.
            shadows enable
          }
          shadow_blur_radius 24
          shadow_color #0000001C
          # Banners are their own small overlay surface, so they get the same
          # frosted treatment as the popups.
          layer_effects "quickshell-banner" {
            blur enable
          }
          default_dim_inactive 0.1
          for_window [app_id="com.gabm.satty"] floating enable
          exec uwsm finalize
        '';
      };

      # Keep Stylix's wallpaper and palette. The clock sits directly on the
      # upper-left of the wallpaper, with a small underline for input feedback.
      stylix.targets.swaylock.colors.enable = false;
      programs.swaylock = {
        enable = true;
        package = pkgs.selfPackages.swaylock-effects;
        settings =
          let
            colors = config.lib.stylix.colors;
            transparent = "00000000";
          in
          {
            clock = true;
            timestr = "%H:%M";
            datestr = "%A, %B %d";
            # Cairo's toy text API does not fall back for missing glyphs.
            # This face, installed by the fonts aspect, covers Latin and CJK.
            font = "Noto Sans CJK SC";
            indicator = true;
            indicator-radius = 120;
            indicator-thickness = 3;
            # The native position options refer to the indicator's centre.
            # These offsets put the clock's ink about 64 logical pixels in.
            indicator-x-position = 184;
            indicator-y-position = 187;
            indicator-caps-lock = true;

            effect-blur = "7x3";
            effect-vignette = "0.55:0.35";
            color = colors.base00;
            inside-color = transparent;
            inside-clear-color = transparent;
            inside-caps-lock-color = transparent;
            inside-ver-color = transparent;
            inside-wrong-color = transparent;

            ring-color = transparent;
            ring-clear-color = colors.base04;
            ring-caps-lock-color = colors.base0A;
            ring-ver-color = transparent;
            ring-wrong-color = colors.base08;
            key-hl-color = colors.base0D;
            bs-hl-color = colors.base0E;
            caps-lock-key-hl-color = colors.base0A;
            caps-lock-bs-hl-color = colors.base0E;

            line-color = transparent;
            line-clear-color = transparent;
            line-caps-lock-color = transparent;
            line-ver-color = transparent;
            line-wrong-color = transparent;
            separator-color = transparent;

            text-color = colors.base05;
            text-clear-color = colors.base04;
            text-caps-lock-color = colors.base0A;
            text-ver-color = colors.base0B;
            text-wrong-color = colors.base08;
            text-clear = "Cleared";
            text-ver = "Verifying";
            text-wrong = "Try again";
            layout-bg-color = "${colors.base00}d9";
            layout-border-color = transparent;
            layout-text-color = colors.base05;
          };
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
          Description = "GNOME PolicyKit Authentication Agent for Sway";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
          ConditionEnvironment = "XDG_SESSION_DESKTOP=sway";
        };
        Service = {
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      services = {
        udiskie.enable = true;
      };

      systemd.user.services.udiskie.Unit.ConditionEnvironment = "XDG_SESSION_DESKTOP=sway";
    };
}
