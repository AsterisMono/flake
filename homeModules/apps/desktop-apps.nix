{
  unstablePkgs,
  pkgs,
  lib,
  osConfig,
  ...
}:
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

  home.packages = with unstablePkgs; [
    dbeaver-bin
    obsidian
    bitwarden-desktop
    vlc
    spotify
    prismlauncher
    helvum
  ];
}
// lib.optionalAttrs osConfig.services.xserver.desktopManager.gnome.enable {
  dconf.settings = {
    "org/gnome/shell/keybindings" = {
      show-screenshot-ui = [ "<Shift><Super>s" ];
    };
  };

  home.packages = with pkgs.gnomeExtensions; [
    appindicator
    clipboard-indicator
    dash-to-dock
    system-monitor
    xremap
    blur-my-shell
    kimpanel
  ];
}
