{
  pkgs,
  unstablePkgs,
  system,
  lib,
  ...
}:
let
  isDarwin = system == "aarch64-darwin";
  homePackages = with unstablePkgs; [
    dbeaver-bin
    obsidian
    bitwarden-desktop
    vlc
    spotify
    prismlauncher
  ];
  darwinOnlyPackages = with unstablePkgs; [
    ice-bar
    google-chrome # chromium is not available on darwin
    alt-tab-macos
    maccy
    shottr
    raycast
    rectangle
    ice-bar
    insomnia
    stats
    chatgpt
    pkgs.tailscale
    pkgs.flakePackages.orbstack
  ];
  linuxOnlyModules = [
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
in
{
  imports = [
    ./vscode
    ./firefox
  ]
  ++ lib.optionals (!isDarwin) linuxOnlyModules;

  home.packages = homePackages ++ lib.optionals isDarwin darwinOnlyPackages;

  xdg.configFile."ghostty/config".source = ./ghostty.config;
}
