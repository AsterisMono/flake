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

  programs.kitty = {
    enable = true;
    shellIntegration = {
      enableFishIntegration = true; 
      mode = "no-cursor";
    };
    theme = "Afterglow";
    settings = {
      cursor_shape = "block";
      cursor_blink_interval = 0;
    };
  };

}
