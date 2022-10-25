{ config, pkgs, ... }:

{
  imports = [
    ./git.nix
  ];
  home-manager.users.cmiki.home.stateVersion = "22.05";
  users.users.cmiki = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "docker" "networkmanager" "input" ];
    shell = pkgs.fish;
  };
}