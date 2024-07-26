{
  description = "Miki's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    devenv.url = "github:cachix/devenv";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

  outputs = inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

      imports = [
        inputs.devenv.flakeModule
      ];

      flake =
        {
          lib = {
            bundleModules = import ./utils/bundle-modules.nix inputs.nixpkgs.lib;
          };
          nixosConfigurations = import ./configurations self;
          nixosModules = {
            common = self.lib.bundleModules ./nixosModules/common;
            desktop = self.lib.bundleModules ./nixosModules/desktop;
            server = self.lib.bundleModules ./nixosModules/server;
          };
          homeModules.home = self.lib.bundleModules ./homeModules;
          overlays.amono-nur = import ./overlays/amono-nur.nix inputs;
        };

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        devenv.shells.default = {
          packages = with pkgs; [ nixpkgs-fmt nil just ];

          pre-commit.hooks.nixpkgs-fmt.enable = true;
        };
      };
    };
}
