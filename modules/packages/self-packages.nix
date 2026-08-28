{ inputs, ... }:
{
  flake.overlays.selfPackages = final: _prev: {
    selfPackages = inputs.self.packages.${final.stdenv.hostPlatform.system};
  };

  flake.modules.nixos.base.nixpkgs.overlays = [ inputs.self.overlays.selfPackages ];
}
