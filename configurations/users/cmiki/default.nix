{ config, pkgs, ... }:

{
  imports = [
    ./git.nix
  ];
  users.users.cmiki = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "docker" "networkmanager" "input" ];
    shell = pkgs.fish;
  };
}