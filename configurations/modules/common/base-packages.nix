{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    killall
    gnumake
    gcc
    ripgrep
  ];

  programs.git = {
    enable = true;
  };
}
