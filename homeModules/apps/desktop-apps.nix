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
  chromiumModule = _: {
    programs.chromium = {
      enable = !isDarwin;
      commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
        "--enable-wayland-ime"
      ];
    };
  };
  linuxOnlyModules = [
    ./fcitx5
    ./wemeet
    chromiumModule
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
