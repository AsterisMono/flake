{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gnumake
    htop
    neofetch
  ];
}
