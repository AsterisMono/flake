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

    isd # isd is a tool for managing systemd services
  ];

  boot.supportedFilesystems = [
    "btrfs"
    "ext4"
    "exfat"
    "fat32"
  ];

  networking.hostName = lib.mkDefault hostname;

  # This is too slow
  documentation.man.generateCaches = false;
}
