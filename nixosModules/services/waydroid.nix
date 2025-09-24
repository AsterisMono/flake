{ pkgs, ... }:
{
  virtualisation.waydroid.enable = true;
  environment.systemPackages = [
    pkgs.nur.repos.ataraxiasjel.waydroid-script
  ];
}
