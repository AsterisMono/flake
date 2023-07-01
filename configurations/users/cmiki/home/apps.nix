{ config, pkgs, ... }:

{
  # Desktop Apps
  home.packages = with pkgs;[
    google-chrome
    firefox
    telegram-desktop
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
  };
}
