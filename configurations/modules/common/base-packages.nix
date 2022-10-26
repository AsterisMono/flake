{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    htop
    neofetch
  ];

  programs.git = {
    enable = true;
  };
}
