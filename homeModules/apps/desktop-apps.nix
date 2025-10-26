{
  unstablePkgs,
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

  dconf.settings = lib.mkIf osConfig.services.xserver.desktopManager.gnome.enable {
    "org/gnome/shell/keybindings" = {
      show-screenshot-ui = [ "<Shift><Super>s" ];
    };
  };
}
