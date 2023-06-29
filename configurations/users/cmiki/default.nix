{ config, pkgs, ... }:

{
  imports = [
    ./git.nix
    ./cnf.nix
    ./helix.nix
  ];

  users.users.cmiki = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "docker" "networkmanager" "input" ];
    shell = pkgs.fish;
    initialHashedPassword = "$6$a1m7k9D8YB4CnDqv$ZOEZ40sles1ibSoYUv365CWWpplxkHsoDIEkKTZW1pZZBzcUH0Cfjy1G0ssq5rviKaH/Z1MIEnmrgDZPR.V1Y/";
  };

  home-manager.users.cmiki.xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  home-manager.users.cmiki.home.stateVersion = "23.05";
}
