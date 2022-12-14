{ config, pkgs, lib, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    vscode.fhs
    nodejs-16_x
    nixpkgs-fmt
    tdesktop
    libsForQt5.kleopatra
  ];

  # needed for store VS Code auth token
  services.gnome.gnome-keyring.enable = true;
}
