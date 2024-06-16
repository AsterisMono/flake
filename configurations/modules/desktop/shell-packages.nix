{ pkgs, ... }:

{
  boot.supportedFilesystems = [ "ntfs" ]; # ntfs-3g

  environment.systemPackages = with pkgs; [
    htop
  ];

  programs.fish.enable = true;
}
