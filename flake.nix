{
  description = "Miki's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    let
      nixos = import ./configurations/nixos.nix inputs;
      collectFiles = import ./utils/collect-files.nix inputs.nixpkgs.lib;
    in
    {
      nixosConfigurations = nixos.configs;
      lib = {
        inherit collectFiles;
      };
    };
}
