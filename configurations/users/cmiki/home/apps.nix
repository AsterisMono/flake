{ config, pkgs, ... }:

{
  # Desktop Apps
  home.packages = with pkgs;[
    google-chrome
    firefox
    telegram-desktop
    libsForQt5.neochat
    amono-nur.sqlitestudio
    nheko
  ];

  # Command-line Apps
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };

  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "plugin-git";
        src = pkgs.fishPlugins.plugin-git.src;
      }
    ];
    shellInit = "set fish_greeting \"\"";
    shellAliases = {
      ".." = "cd ../";
      "c" = "clear";
      "n" = "nvim";
    };
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

  programs.lazygit.enable = true;
}
