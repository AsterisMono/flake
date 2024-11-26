{ flake, ... }:
{
  nixpkgs.overlays = [
    flake.overlays.flake-packages
  ];
}
