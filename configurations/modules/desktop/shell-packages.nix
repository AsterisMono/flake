{ pkgs, ... }:

{
  boot.supportedFilesystems = [ "ntfs" ]; # ntfs-3g

  environment.systemPackages = with pkgs; [
    htop
    neofetch
  ];

  programs.fish.enable = true;
}
