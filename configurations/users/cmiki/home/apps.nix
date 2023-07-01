{ config, pkgs, ... }:

{
  home.packages = with pkgs;[
    google-chrome
    firefox
    telegram-desktop
  ];
}