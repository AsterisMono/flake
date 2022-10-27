{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    htop
    neofetch
    killall
    gnupg
  ];

  programs.git = {
    enable = true;
  };
}
