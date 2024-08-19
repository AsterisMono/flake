{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    killall
  ];

  programs = {
    git.enable = true;
    fish.enable = true;
  };

  users.users.cmiki.shell = lib.mkForce pkgs.bashInteractive;
}
