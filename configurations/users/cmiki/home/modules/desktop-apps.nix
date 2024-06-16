{ config, pkgs, nvimConfig, ... }:
{
  # Desktop Apps
  home.packages = with pkgs;[
    google-chrome
  # firefox
  # telegram-desktop
  # amono-nur.sqlitestudio
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };

}
