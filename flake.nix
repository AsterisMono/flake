{
  description = "Miki's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    devenv.url = "github:cachix/devenv";
    flake-parts.url = "github:hercules-ci/flake-parts";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    myNurPackages = {
      url = "github:AsterisMono/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvim-config = {
      url = "git+https://github.com/AsterisMono/nvim-config?ref=light";
      flake = false;
    };
    secrets = {
      url = "git+https://github.com/AsterisMono/secrets";
      flake = false;
    };
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = nixpkgs.lib.systems.flakeExposed;

      flake =
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

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        devenv.shells.default = {
          packages = with pkgs; [ nixpkgs-fmt nil ];

          pre-commit = {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
            };
          };
        };
      };
    };
}
