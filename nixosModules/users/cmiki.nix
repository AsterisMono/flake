{ flake, pkgs, ... }:

with pkgs.lib;
{
  users.users.cmiki = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "docker" "networkmanager" "input" "docker" ];
    shell = pkgs.fish;
    initialHashedPassword = "$6$a1m7k9D8YB4CnDqv$ZOEZ40sles1ibSoYUv365CWWpplxkHsoDIEkKTZW1pZZBzcUH0Cfjy1G0ssq5rviKaH/Z1MIEnmrgDZPR.V1Y/";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIESmYINQDHO1+7FY0mDdcl+UIu2RPuMNOtj242d2N3cf"
    ];
  };
}
