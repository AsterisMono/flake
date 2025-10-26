{
  description = "Noa's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    determinate-nix = {
      url = "github:DeterminateSystems/nix-src";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.git-hooks-nix.follows = "git-hooks";
    };
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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wrapper-manager.url = "github:viperML/wrapper-manager";
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs-stable.follows = "nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    stylix = {
      url = "github:nix-community/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs =
    inputs@{
      self,
      flake-utils,
      ...
    }:
    let
      inherit (inputs.nixpkgs) lib;
      secretsPath = ./secrets;
      assetsPath = ./assets;
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
      globalSpecialArgs = {
        inherit
          inputs
          secretsPath
          assetsPath
          ;
        inherit (self)
          nixosModules
          homeModules
          ;
        overlays = lib.attrValues self.overlays;
      };
    in
    {
      nixosModules = modulesFromDirectoryRecursive ./nixosModules;

      homeModules = modulesFromDirectoryRecursive ./homeModules;

      nixosConfigurations = lib.packagesFromDirectoryRecursive {
        callPackage =
          path: _:
          let
            hostname = lib.removeSuffix ".nix" (builtins.baseNameOf path);
            system = if hostname == "ivy" then "aarch64-linux" else "x86_64-linux";
            unstablePkgs = import inputs.nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
              overlays = lib.attrValues self.overlays;
            };
          in
          self.lib.withOfflineInstaller {
            flake = self;
            inherit lib;
            nixosConfig = lib.nixosSystem {
              inherit system;
              specialArgs = globalSpecialArgs // {
                inherit hostname system unstablePkgs;
              };
              modules = [
                path
                ./hardwares/${hostname}.nix
                self.nixosModules.common
                inputs.disko.nixosModules.disko
                inputs.home-manager-nixos.nixosModules.home-manager
                inputs.sops-nix.nixosModules.sops
                inputs.stylix.nixosModules.stylix
                inputs.niri.nixosModules.niri
              ];
            };
          };

        directory = ./nixosConfigurations;
      };

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
        extended-lib = import ./overlays/extended-lib.nix self;
        nix-vscode-extensions = inputs.nix-vscode-extensions.overlays.default;
        inherit (inputs.niri.overlays) niri;
        determinate-nix = inputs.determinate-nix.overlays.default;
        inherit (inputs.nur.overlays) default;
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
        pkgs = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
          overlays = lib.attrValues self.overlays;
        };
      in
      rec {
        packages =
          lib.filterAttrs
            (
              pname: package:
              if builtins.hasAttr "meta" package then builtins.elem system package.meta.platforms else true
            )
            (
              lib.packagesFromDirectoryRecursive {
                inherit (pkgs) callPackage;
                directory = ./packages;
              }
            );

        checks = {
          pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt-rfc-style.enable = true;
              statix.enable = true;
            };
          };
        }
        // inputs.deploy-rs.lib."${system}".deployChecks self.deploy;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixd
            just
            deploy-rs
            nixfmt-rfc-style
            ssh-to-age
            sops
            jq
            openssh
            wireguard-tools
            git-agecrypt
          ];
          inherit (checks.pre-commit-check) shellHook;
          buildInputs = checks.pre-commit-check.enabledPackages;
        };
      }
    );
}
