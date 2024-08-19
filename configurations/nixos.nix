flake:
let
  mkLinux = { hostname, username ? "cmiki", system ? "x86_64-linux", type ? "desktop", customConfig ? { }, extraModules ? [ ] }:
    let
      unstablePkgs = import flake.inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      specialArgs = {
        inherit flake system hostname username type;
        inherit (flake.inputs) secrets;
        unstablePkgs = unstablePkgs;
      };
      homeModule = {
        home-manager = {
          users.${username}.imports = [
            flake.homeModules.common
            flake.homeModules.nixos
          ];
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = ".bak";
          extraSpecialArgs = specialArgs;
        };
      };
    in
    {
      name = hostname;
      value = flake.inputs.nixpkgs.lib.nixosSystem {
        inherit specialArgs system;
        modules = [
          ./hardwares/${hostname}.nix
          ../nixosModules/users/${username}.nix
          flake.nixosModules.common
          flake.nixosModules.${type}
          flake.inputs.nur.nixosModules.nur
          flake.inputs.disko.nixosModules.disko
          { networking.hostName = hostname; }
          { config.amono = customConfig; }
        ] ++ extraModules
        ++ (if type == "desktop" then [ flake.inputs.home-manager-nixos.nixosModules.home-manager homeModule ] else [ ]);
      };
    };
in
builtins.listToAttrs (map mkLinux [
  {
    hostname = "luminara";
    customConfig = {
      desktop = {
        suite = "hyprland";
        gpu = "amdgpu";
      };
    };
  }
  {
    hostname = "celestia";
    type = "server";
    customConfig = {
      server.proxy.enable = true;
    };
  }
])
