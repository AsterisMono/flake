{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    distrobox
  ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
  };
}
