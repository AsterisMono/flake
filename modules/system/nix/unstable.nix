{ inputs, ... }:
{
  flake-file.inputs.nixpkgs-unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";

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

  # Single unfree-enabled unstable package set for every perSystem package
  # definition, so packages do not each import their own instance.
  perSystem =
    { system, ... }:
    {
      _module.args.pkgsUnstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    };
}
