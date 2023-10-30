{ sshPublicKey, pkgs, isDesktop, ... }:
{
  users.users.cmiki = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "docker" "networkmanager" "input" ];
    shell = if isDesktop then pkgs.fish else pkgs.bash;
    initialHashedPassword = "$6$a1m7k9D8YB4CnDqv$ZOEZ40sles1ibSoYUv365CWWpplxkHsoDIEkKTZW1pZZBzcUH0Cfjy1G0ssq5rviKaH/Z1MIEnmrgDZPR.V1Y/";
    openssh.authorizedKeys.keys = [
      sshPublicKey
    ];
  };

  # Use home-manager on desktops
  home-manager.users.cmiki.imports = if isDesktop then [ ./home ] else [];
}
