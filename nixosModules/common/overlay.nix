{ flake, ... }:
{
  nixpkgs.overlays = [
    flake.overlays.amono-nur
    flake.overlays.flake-packages
    flake.inputs.nix-relic.overlays.additions
  ];
}
