{
  unstablePkgs,
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  useGnome = osConfig.services.xserver.desktopManager.gnome.enable;
in
{
  imports = [
    ./vscode
    ./firefox
    ./fcitx5
    ./chromium
    ./obs-studio
    ./xpipe
    ./telegram-desktop
    ./moonlight-qt
    ./kitty
    ./vicinae
    ./flatpaks
  ];

  home.packages =
    with unstablePkgs;
    [
      dbeaver-bin
      obsidian
      bitwarden-desktop
      vlc
      spotify
      prismlauncher
      helvum
      figma-linux
      splayer
    ]
    ++ lib.optionals useGnome (
      [ pkgs.flakePackages.vicinae-gnome-extension ]
      ++ (with pkgs.gnomeExtensions; [
        appindicator
        dash-to-dock
        system-monitor
        xremap
        blur-my-shell
        kimpanel
        gsconnect
        mpris-label
        caffeine
      ])
    );

  home.sessionVariables = {
    "NIXOS_OZONE_WL" = "1"; # for any ozone-based browser & electron apps to run on wayland
    "MOZ_ENABLE_WAYLAND" = "1"; # for firefox to run on wayland
    "MOZ_WEBRENDER" = "1";
    # enable native Wayland support for most Electron apps
    "ELECTRON_OZONE_PLATFORM_HINT" = "auto";
    # misc
    "_JAVA_AWT_WM_NONREPARENTING" = "1";
    "QT_WAYLAND_DISABLE_WINDOWDECORATION" = "1";
    "QT_QPA_PLATFORM" = "wayland";
    "SDL_VIDEODRIVER" = "wayland";
    "GDK_BACKEND" = "wayland";
    "XDG_SESSION_TYPE" = "wayland";
  };

  stylix = {
    inherit (osConfig.stylix) image base16Scheme;
    cursor = {
      package = pkgs.capitaine-cursors;
      name = "capitaine-cursors";
      size = 32;
    };
    icons = {
      enable = true;
      package = pkgs.tela-icon-theme;
      dark = "Tela-dark";
      light = "Tela-light";
    };
    opacity.terminal = 0.9;
    targets.firefox.profileNames = [ "default" ];
    targets.neovim.enable = false;
  };
}
// lib.optionalAttrs useGnome {
  dconf.settings = {
    "org/gnome/shell/keybindings" = {
      show-screenshot-ui = [ "<Shift><Super>s" ];
    };
    "org/gnome/shell/extensions/mpris-label" = {
      divider-string = " - ";
      extension-index = 3;
      extension-place = "left";
      left-click-action = "activate-player";
      right-click-action = "open-menu";
      left-padding = 0;
      right-padding = 0;
      second-field = "";
      show-icon = "left";
      symbolic-source-icon = true;
      use-album = true;
    };
  };
}
