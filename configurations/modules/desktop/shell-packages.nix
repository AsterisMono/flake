{ pkgs, ... }:

{
  boot.supportedFilesystems = [ "ntfs" ]; # ntfs-3g

  programs.fish.enable = true;
}
