{ config, pkgs, ... }:

{
  imports = [
    ./git.nix
    ./firefox
    ./cnf.nix
  ];
  home-manager.users.cmiki.home.stateVersion = "22.11";
  users.users.cmiki = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "docker" "networkmanager" "input" ];
    shell = pkgs.fish;
    initialHashedPassword = "$6$a1m7k9D8YB4CnDqv$ZOEZ40sles1ibSoYUv365CWWpplxkHsoDIEkKTZW1pZZBzcUH0Cfjy1G0ssq5rviKaH/Z1MIEnmrgDZPR.V1Y/"; # For build-vm only
  };
}
