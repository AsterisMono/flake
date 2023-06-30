{ config, pkgs, lib, ... }:

{
  imports = [
    # Desktop Manager and Display Manager are bundled to maximize compatibility.
    ./dms/gnome.nix

    ./fonts.nix
    ./audio.nix
    ./ime.nix
  ];

  environment.systemPackages = with pkgs; [
    vim
    wget
  ];
}
