{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    htop
    neofetch
    killall
  ];

  programs.git = {
    enable = true;
  };
}
