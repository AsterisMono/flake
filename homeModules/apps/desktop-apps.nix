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
    telegram-desktop
    obsidian
    bitwarden-desktop
    pavucontrol
    nmgui
    vlc
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
    ./kde-connect
    ./chromium
    ./obs-studio
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
