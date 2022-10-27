{ config, pkgs, ... }:

{
  # Choose a proxy provider.
  imports = [
    ./clash.nix
  ];
}
