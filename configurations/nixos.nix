flake:
let
  mkLinux =
    {
      hostname,
      username ? "cmiki",
      extraUsers ? [ ],
      system ? "x86_64-linux",
      type ? "desktop",
      customConfig ? { },
      extraModules ? [ ],
      payloads ? [ ],
      pkgs ? flake.inputs.nixpkgs,
    }:
    let
      unstablePkgs = import flake.inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      specialArgs = {
        inherit
          flake
          system
          hostname
          username
          type
          unstablePkgs
          ;
        inherit (flake.inputs) secrets;
      };
    in
    {
      name = hostname;
      value = pkgs.lib.nixosSystem {
        inherit specialArgs system;
        modules =
          [
            ./hardwares/${hostname}.nix
            ../nixosModules/users/${username}.nix
            flake.nixosModules.common
            flake.nixosModules.${type}
            flake.inputs.disko.nixosModules.disko
            flake.inputs.stylix.nixosModules.stylix
            flake.inputs.home-manager-nixos.nixosModules.home-manager
            { networking.hostName = hostname; }
            { config.amono = customConfig; }
          ]
          ++ extraModules
          ++ map (payload: flake.nixosModules."payload-${payload}") payloads
          ++ map (user: ../nixosModules/users/${user}.nix) extraUsers;
      };
    };
in
builtins.listToAttrs (
  map mkLinux [
    # home-manager is implicitly enabled for desktops but not servers
    # tailscale is enabled for all machines
    # proxy is enabled by default for all desktops, and by enabling proxy USTC substituter will be used
    {
      hostname = "lunaria";
      customConfig = {
        proxy.enable = true;
        desktop = {
          plasma.enable = true;
          gpu = "amdgpu";
        };
      };
    }
    {
      hostname = "stellarbase";
      type = "server";
      payloads = [ "docker" ];
      customConfig = { };
    }
    {
      hostname = "ccnu-4090-2";
      type = "server";
      customConfig = {
        homeManager.enable = true;
        tailscale = {
          advertiseTags = [ "tag:gpu" ];
          advertiseRoutes = [ "172.0.0.0/16" ];
        };
      };
      payloads = [ ];
    }
    {
      hostname = "zinnia";
      type = "desktop";
      customConfig = {
        proxy.enable = true;
        desktop = {
          plasma.enable = true;
          gpu = "amdgpu";
        };
      };
    }
    {
      hostname = "ivy";
      type = "server";
      customConfig = {
        proxy = {
          enable = true;
          tunMode = true;
        };
        tailscale = {
          advertiseRoutes = [ "198.18.0.1/16" ];
        };
      };
    }
    {
      hostname = "picea";
      type = "server";
      customConfig = {
        proxy.enable = true;
        tailscale = {
          advertiseTags = [ "tag:ci" ];
        };
      };
    }
  ]
)
