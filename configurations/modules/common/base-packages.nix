{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    htop
    neofetch
    killall
    gnupg
  ];

  programs.git = {
    enable = true;
  };

  programs.fish.enable = true;
}
