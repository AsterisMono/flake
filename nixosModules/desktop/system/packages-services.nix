{ pkgs, ... }:

{
  networking.networkmanager.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.supportedFilesystems = [ "ntfs" ]; # ntfs-3g

  programs.fish.enable = true;

  services.flatpak.enable = false;

  environment.systemPackages = with pkgs; [
    xdg-user-dirs
  ];
}
