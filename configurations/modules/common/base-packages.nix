{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    vim wget
  ];

  programs.git = {
    enable = true;
  };
}
