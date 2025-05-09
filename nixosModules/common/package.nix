{ lib, hostname, ... }:
{
  imports = [
    ./base-packages.nix
    ./i18n.nix
    ./nix-environment.nix
  ];

  networking.hostName = lib.mkDefault hostname;
}
