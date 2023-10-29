{ pkgs, isDesktop, ... }:
{
  users.users.cmiki = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "docker" "networkmanager" "input" ];
    shell = if isDesktop then pkgs.fish else pkgs.bash;
    initialHashedPassword = "$6$a1m7k9D8YB4CnDqv$ZOEZ40sles1ibSoYUv365CWWpplxkHsoDIEkKTZW1pZZBzcUH0Cfjy1G0ssq5rviKaH/Z1MIEnmrgDZPR.V1Y/";
  };

  # Use home-manager on desktops
  imports = if isDesktop then [ ./home ] else [];
}
