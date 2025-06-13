{ pkgs, lib, ... }:

{
  networking.networkmanager.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # do not need to keep too much generations
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;

  boot.supportedFilesystems = [ "ntfs" ]; # ntfs-3g

  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    xdg-user-dirs
  ];
}
