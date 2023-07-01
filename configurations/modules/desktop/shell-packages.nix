{ pkgs, ... }:

{
  boot.supportedFilesystems = [ "ntfs" ]; # ntfs-3g

  environment.systemPackages = with pkgs; [
    gnumake
    htop
    neofetch
    gcc
    ripgrep
  ];
}
