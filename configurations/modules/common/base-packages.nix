{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    killall
    gnupg
  ];

  programs.git = {
    enable = true;
  };

  programs.fish = {
    enable = true;
  };
}
