{
  description = "Miki's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    devenv.url = "github:cachix/devenv";
    nixos-flake.url = "github:srid/nixos-flake";
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
        inputs.nixos-flake.flakeModule
        inputs.devenv.flakeModule
      ];

      flake =
        let
          username = "cmiki";
          nixos = import ./configurations/nixos.nix inputs;
        in
        {
          lib = {
            collectModules = import ./utils/collect-modules.nix inputs.nixpkgs.lib;
          };
          nixosConfigurations = nixos.configs;
          darwinConfigurations = {
            momoka = self.nixos-flake.lib.mkMacosSystem {
              nixpkgs.hostPlatform = "aarch64-darwin";
              imports = [
                # self.nixosModules.darwin
                ({ pkgs, ... }: {
                  # Used for backwards compatibility, please read the changelog before changing.
                  # $ darwin-rebuild changelog
                  system.stateVersion = 4;
                })
                self.darwinModules_.home-manager
                {
                  home-manager.users.${username} = {
                    imports = [
                      # self.homeModules.common
                      # self.homeModules.darwin
                    ];
                    home.stateVersion = "22.11"; # TODO
                  };
                }
              ];
            };
          };
          nixosModules = self.lib.collectModules ./nixos/modules;
          homeModules = {
            common = self.lib.collectModules ./homeModules/common;
            linux = self.lib.collectModules ./homeModules/linux;
            darwin = self.lib.collectModules ./homeModules/darwin;
          };
        };

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        devenv.shells.default = {
          packages = with pkgs; [ nixpkgs-fmt nil just ];

          pre-commit.hooks.nixpkgs-fmt.enable = true;
        };
      };
    };
}
