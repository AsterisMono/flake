{
  pkgs,
  lib,
  hostname,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    killall
    gnumake
  ];

  boot.supportedFilesystems = [
    "btrfs"
    "ext4"
    "exfat"
    "fat32"
  ];

  networking.hostName = lib.mkDefault hostname;
}
