{ flake, ... }:
{
  nixpkgs.overlays = [
    flake.overlays.amono-nur
  ];
}
