{ config, pkgs, ... }:

{
  # Choose a proxy provider.
  imports = [
    ./dae.nix
  ];
}
