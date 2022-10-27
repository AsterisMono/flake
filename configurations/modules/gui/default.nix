{ config, pkgs, lib, ... }:

{
  imports = [
    # Desktop Manager and Display Manager are bundled to maximize compatibility.
    ./plasma

    ./fonts.nix
    ./audio.nix
    ./ime.nix
    ./xdg-userdirs.nix
  ];

  environment.systemPackages = with pkgs; [
    vim
    wget
  ];
}
