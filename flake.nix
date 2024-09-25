{
  description = "Miki's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    flake-parts.url = "github:hercules-ci/flake-parts";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs.url = "github:serokell/deploy-rs";
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
    home-manager-nixos = {
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
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-24.05-darwin";
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    home-manager-darwin = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ilgaak = {
      url = "github:AsterisMono/ilgaak";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

      imports = [
        inputs.ilgaak.flakeModule
      ];

      ilgaak.enable = true;

      flake =
        {
          lib = {
            bundleModules = import ./utils/bundle-modules.nix inputs.nixpkgs.lib;
          };
          nixosConfigurations = import ./configurations/nixos.nix self;
          darwinConfigurations = import ./configurations/darwin.nix self;
          nixosModules = {
            common = self.lib.bundleModules ./nixosModules/common;
            desktop = self.lib.bundleModules ./nixosModules/desktop;
            server = self.lib.bundleModules ./nixosModules/server;
          };
          darwinModules.darwin = self.lib.bundleModules ./darwinModules;
          homeModules = {
            common = self.lib.bundleModules ./homeModules/common;
            darwin = self.lib.bundleModules ./homeModules/darwin;
            nixos = self.lib.bundleModules ./homeModules/nixos;
          };
          overlays = {
            amono-nur = import ./overlays/amono-nur.nix inputs;
            flake-packages = import ./overlays/flake-packages.nix self;
          };
          deploy = {
            nodes = {
              celestia = {
                hostname = "celestia";
                profiles.system = {
                  user = "root";
                  path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.celestia;
                };
              };
              stellarbase = {
                hostname = "stellarbase";
                profiles.system = {
                  user = "root";
                  path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.stellarbase;
                };
              };
            };
          };

          # This is highly advised, and will prevent many possible mistakes
          checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
        };

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        checks = {
          pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              statix.enable = true;
            };
          };
        };
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ nixd just deploy-rs nh ];
          inherit (self'.checks.pre-commit-check) shellHook;
          buildInputs = self'.checks.pre-commit-check.enabledPackages;
        };
        packages = {
          torus-font = pkgs.callPackage ./packages/torus { };
        };
      };
    };
}
