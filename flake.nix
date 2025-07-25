{
  description = "Noa's NixOS Flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
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
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";
    darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    home-manager-darwin = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      secretsPath = ./secrets;
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
                inherit
                  inputs
                  secretsPath
                  unstablePkgs
                  system
                  hostname
                  ;
                inherit (self)
                  nixosModules
                  homeModules
                  overlays
                  ;
              };
              modules = [
                path
                ./hardwares/${hostname}.nix
                self.nixosModules.common
                inputs.disko.nixosModules.disko
                inputs.home-manager-nixos.nixosModules.home-manager
                inputs.sops-nix.nixosModules.sops
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
                inherit
                  inputs
                  secretsPath
                  unstablePkgs
                  system
                  hostname
                  ;
                inherit (self)
                  homeModules
                  overlays
                  ;
              };
              modules = (builtins.attrValues self.darwinModules) ++ [
                inputs.home-manager-darwin.darwinModules.home-manager
              ];
            };
          }
        ) darwinMachines
      );

      deploy.nodes = lib.packagesFromDirectoryRecursive {
        callPackage =
          path: _:
          let
            hostname = lib.removeSuffix ".nix" (builtins.baseNameOf path);
          in
          {
            inherit hostname;
            sshUser = "root";
            profiles.system = {
              user = "root";
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."${hostname}";
            };
          };
        directory = ./nixosConfigurations;
      };

      overlays = {
        flake-packages = import ./overlays/flake-packages.nix self;
      };

      lib = {
        withOfflineInstaller = import ./lib/withOfflineInstaller.nix;
      };

      templates = builtins.mapAttrs (p: _: {
        path = ./templates/${p};
        description = "${p} template";
      }) (lib.attrsets.filterAttrs (p: t: t == "directory") (builtins.readDir ./templates));
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      rec {
        packages = lib.packagesFromDirectoryRecursive {
          inherit (pkgs) callPackage;
          directory = ./packages;
        };

        checks = {
          pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt-rfc-style.enable = true;
              statix.enable = true;
            };
          };
        } // inputs.deploy-rs.lib."${system}".deployChecks self.deploy;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixd
            just
            deploy-rs
            nh
            nixfmt-rfc-style
            ssh-to-age
            sops
            jq
            openssh
          ];
          inherit (checks.pre-commit-check) shellHook;
          buildInputs = checks.pre-commit-check.enabledPackages;
        };
      }
    );
}
