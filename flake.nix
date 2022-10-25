{
  description = "AsterisMono's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = github:nix-community/NUR;
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
  let
    nixos = import ./configurations/nixos.nix inputs;
  in
  {
    nixosConfigurations = nixos.configs;
  };
}