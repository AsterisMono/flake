{ pkgs, ... }:

{
  boot.supportedFilesystems = [ "ntfs" ]; # ntfs-3g

  programs.fish.enable = true;

  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [
    xdg-user-dirs
  ];
}
