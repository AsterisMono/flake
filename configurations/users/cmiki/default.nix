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
    initialHashedPassword = "$6$a1m7k9D8YB4CnDqv$ZOEZ40sles1ibSoYUv365CWWpplxkHsoDIEkKTZW1pZZBzcUH0Cfjy1G0ssq5rviKaH/Z1MIEnmrgDZPR.V1Y/";
    openssh.authorizedKeys.keys = [
      "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBCwXacTziuH437m46pau7P3h8/51HRW/EXIwrX6XtH9GsvIm/JewxWQlCEEWB2Q+n9j6msbi+ARBR+T8e6mHn34AAAALc3NoOkVjbGlwc2U= ssh:Eclipse"
    ]; # For build-vm only
  };
}
