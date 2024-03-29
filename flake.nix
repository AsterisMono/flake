{
  description = "Miki's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    agenix.url = "github:ryantm/agenix";
    myNurPackages = {
      url = "github:AsterisMono/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvim-config = {
      url = "git+https://github.com/AsterisMono/nvim-config?ref=linux";
      flake = false; 
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
