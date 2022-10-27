{ config, pkgs, ... }:

{
  imports = [
    ./git.nix
    ./firefox
  ];
  home-manager.users.cmiki.home.stateVersion = "22.11";
  users.users.cmiki = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "docker" "networkmanager" "input" ];
    shell = pkgs.fish;
  };
}
