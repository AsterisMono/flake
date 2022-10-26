{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    config.nur.repos.rewine.v2raya
  ];
}
