{
  description = "Noa's NixOS Flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
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
    home-manager-nixos = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+https://github.com/AsterisMono/secrets";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-24.11-darwin";
    darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    home-manager-darwin = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    stylix.url = "github:danth/stylix/release-24.11";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  };

  outputs =
    inputs@{
      self,
      flake-utils,
      nixpkgs,
      ...
    }:
    let
      inherit (inputs.nixpkgs) lib;
      # This recursive attrset pattern is forbidden, but we use it here anyway.
      #
      # The following flake output attributes must be NixOS modules:
      # - nixosModule
      # - nixosModules.name
      modulesFromDirectoryRecursive =
        _dirPath:
        lib.packagesFromDirectoryRecursive {
          callPackage = path: _: import path;
          directory = _dirPath;
        };
      darwinMachines = [
        "Oryx"
        "Fervorine"
      ];
    in
    {
      nixosModules = modulesFromDirectoryRecursive ./nixosModules;

      darwinModules = modulesFromDirectoryRecursive ./darwinModules;

      homeModules = modulesFromDirectoryRecursive ./homeModules;

      nixosConfigurations = lib.packagesFromDirectoryRecursive {
        callPackage =
          path: _:
          let
            system = "x86_64-linux";
            hostname = lib.removeSuffix ".nix" (builtins.baseNameOf path);
            unstablePkgs = import inputs.nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
          in
          self.lib.withOfflineInstaller {
            flake = self;
            inherit lib;
            nixosConfig = lib.nixosSystem {
              inherit system;
              specialArgs = {
                inherit (self)
                  inputs
                  nixosModules
                  homeModules
                  overlays
                  ;
                inherit (inputs) secrets;
                inherit unstablePkgs system hostname;
              };
              modules =
                [
                  path
                  self.nixosModules.common
                  inputs.disko.nixosModules.disko
                  inputs.stylix.nixosModules.stylix
                  inputs.home-manager-nixos.nixosModules.home-manager
                ]
                ++ lib.optionals (hostname != "installer") [
                  inputs.nixos-facter-modules.nixosModules.facter
                  {
                    facter.reportPath = lib.mkDefault ./hardwares/${hostname}.json;
                  }
                ];
            };
          };

        directory = ./nixosConfigurations;
      };

      darwinConfigurations = builtins.listToAttrs (
        builtins.map (
          hostname:
          let
            system = "aarch64-darwin";
            unstablePkgs = import inputs.nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
          in
          {
            name = hostname;
            value = inputs.darwin.lib.darwinSystem {
              inherit system;
              specialArgs = {
                inherit (self) inputs homeModules;
                inherit (inputs) secrets;
                inherit unstablePkgs system hostname;
              };
              modules = (builtins.attrValues self.darwinModules) ++ [
                inputs.home-manager-darwin.darwinModules.home-manager
              ];
            };
          }
        ) darwinMachines
      );

      overlays = {
        flake-packages = import ./overlays/flake-packages.nix self;
      };

      lib = {
        withOfflineInstaller = import ./lib/withOfflineInstaller.nix;
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        packages = {
          torus-font = pkgs.callPackage ./packages/torus { };
        };

        checks = {
          pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt-rfc-style.enable = true;
              statix.enable = true;
            };
          };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixd
            just
            deploy-rs
            nh
            nixfmt-rfc-style
          ];
          inherit (checks.pre-commit-check) shellHook;
          buildInputs = checks.pre-commit-check.enabledPackages;
        };
      }
    );
}
