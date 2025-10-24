{
  unstablePkgs,
  ...
}:
{
  imports = [
    ./vscode
    ./firefox
    ./fcitx5
    ./wemeet
    ./chromium
    ./obs-studio
    ./reminder
    ./xpipe
    ./feishu
    ./qq
    ./telegram-desktop
    ./moonlight-qt
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
