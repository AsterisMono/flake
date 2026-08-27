{ inputs, ... }: {
  flake-file.inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";
    systems.url = "github:nix-systems/default";
  };

  imports = [
    inputs.flake-file.flakeModules.dendritic
  ];
}
