{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    vim wget kate
  ];
}
