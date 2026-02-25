{ pkgs, lib, ... }:

{
  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  networking.networkmanager.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # do not need to keep too much generations
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;

  boot.supportedFilesystems = [ "ntfs" ]; # ntfs-3g

  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    xdg-user-dirs
  ];

  sops.age.keyFile = "/home/cmiki/.config/sops/age/keys.txt";
}
