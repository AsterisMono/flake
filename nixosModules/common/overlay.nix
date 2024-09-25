{ flake, ... }:
{
  nixpkgs.overlays = [
    flake.overlays.amono-nur
    flake.overlays.flake-packages
  ];
}
