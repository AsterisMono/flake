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

      systemd.user.targets."nixos-fake-graphical-session".enable = false;
    };

  flake.modules.homeManager.sway =
    {
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
      wallpaper = pkgs.fetchurl {
        url = "https://r2.requiem.garden/kataomoi.jpg";
        hash = "sha256-1n30bVynUkK650sGyfmD9GoElzqxSUmSpfP7Tb9q2G4=";
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
          output."*".bg = "${wallpaper} fill";
          output."China Star Optoelectronics Technology Co., Ltd MNE007ZA3-4 Unknown" = {
            mode = "2880x1800@120Hz";
            scale = "1.75";
          };
          workspaceAutoBackAndForth = true;
          window = {
            titlebar = false;
            border = 2;
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
                "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
                "XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
                "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
                "XF86AudioRaiseVolume" = "exec wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
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
          default_dim_inactive 0.2
          exec uwsm finalize
        '';
      };

      programs.swaylock.enable = true;

      home.packages = with pkgs; [
        brightnessctl
        wl-clipboard
        sway-contrib.grimshot
        kdePackages.dolphin
        autotiling
        wdisplays
      ];

      home.sessionVariables = {
        "NIXOS_OZONE_WL" = "1";
        "ELECTRON_OZONE_PLATFORM_HINT" = "auto";
      };

      services.gnome-keyring.enable = true;
      services.lxqt-policykit-agent.enable = true;
      systemd.user.services.lxqt-policykit-agent.Unit.After = [ "graphical-session.target" ];
      services.mako.enable = true;
    };
}
