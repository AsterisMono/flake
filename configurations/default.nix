flake:
let
  unstablePkgs = import flake.inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  specialArgs = {
    inherit flake unstablePkgs;
    inherit (flake.inputs) secrets;
  };
  homeModule = {
    home-manager = {
      users.cmiki.imports = [ flake.homeModules.home ];
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = ".bak";
      extraSpecialArgs = specialArgs;
    };
  };
  mkLinux = { name, customConfig ? { }, extraModules ? [ ], type ? "desktop" }:
    {
      inherit name;
      value = flake.inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        inherit specialArgs;
        modules = [
          ./hardwares/${name}.nix
          ../nixosModules/users/cmiki.nix
          flake.nixosModules.common
          flake.nixosModules.${type}
          flake.inputs.nur.nixosModules.nur
          flake.inputs.disko.nixosModules.disko
          flake.inputs.home-manager.nixosModules.home-manager
          homeModule
          { networking.hostName = name; }
          { config.amono = customConfig; }
        ] ++ extraModules;
      };
    };
in
builtins.listToAttrs (map mkLinux [
  {
    name = "luminara";
    customConfig = {
      desktop = {
        suite = "hyprland";
        gpu = "amdgpu";
      };
    };
  }
  {
    name = "celestia";
    customConfig = {
      desktop = {
        suite = "plasma";
        gpu = "intel";
      };
    };
  }
])
