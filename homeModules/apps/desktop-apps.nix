{
  unstablePkgs,
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
    ./flatpaks
  ];

  home.packages = with unstablePkgs; [
    dbeaver-bin
    obsidian
    bitwarden-desktop
    vlc
    spotify
    prismlauncher
  ];
}
