{ config, pkgs, lib, ... }:

{
  imports = [
    # Desktop Manager and Display Manager are bundled to maximize compatibility.
    ./xfce-i3

    ./fonts.nix
    ./audio.nix
    ./ime.nix
  ];

  environment.systemPackages = with pkgs; [
    vim
    wget
  ];
}
