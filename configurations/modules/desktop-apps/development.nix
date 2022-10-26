{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    vscode.fhs
    nodejs-16_x
  ];

  # needed for store VS Code auth token
  services.gnome.gnome-keyring.enable = true;
}
