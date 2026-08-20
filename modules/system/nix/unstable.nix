{ inputs, ... }:
{
  flake-file.inputs.nixpkgs-unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";

  flake.modules.nixos.nix = {
    nixpkgs.overlays = [
      (_final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          system = prev.stdenv.hostPlatform.system;
          inherit (prev) config;
        };
      })
    ];
  };
}
