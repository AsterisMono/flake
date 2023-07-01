{ config, pkgs, ... }:

{
  # Desktop Apps
  home.packages = with pkgs;[
    google-chrome
    firefox
    telegram-desktop
    libsForQt5.neochat
  ];

  # Command-line Apps
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
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
}
