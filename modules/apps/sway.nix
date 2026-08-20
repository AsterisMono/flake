_: {
  flake.modules.nixos.sway = { pkgs, ... }: {
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
      menu = "vicinae toggle";
      modifier = "Mod4";
      terminal = "kitty";
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
          input."*" = {
            natural_scroll = "enabled";
            xkb_options = "ctrl:nocaps";
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
          floating.titlebar = false;
          focus.followMouse = false;
          keybindings =
            removeAttrs
              (lib.mkOptionDefault {
                "${modifier}+q" = "exec ${terminal}";
                "${modifier}+c" = "kill";
                "${modifier}+space" = "exec ${menu}";
                "${modifier}+Alt+Space" = "focus mode_toggle";
                "${modifier}+Shift+s" = "exec grimshot copy anything";
              })
              [
                "${modifier}+Return"
                "${modifier}+Shift+q"
                "${modifier}+d"
              ];
        };
        extraConfig = ''
          seat * hide_cursor when-typing enable
          blur enable
          default_dim_inactive 0.2
          exec uwsm finalize
        '';
      };

      home.packages = with pkgs; [
        brightnessctl
        wl-clipboard
        sway-contrib.grimshot
        kdePackages.dolphin
        autotiling
        wdisplays
      ];

      services.gnome-keyring.enable = true;
      services.mako.enable = true;
    };
}
