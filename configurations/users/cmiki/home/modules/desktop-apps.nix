{ config, pkgs, nvimConfig, ... }:
{
  # Desktop Apps
  home.packages = with pkgs;[
    firefox
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };
}
