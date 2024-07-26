flake:
let
  mkLinux = { name, system ? "x86_64-linux", type ? "desktop", customConfig ? { }, extraModules ? [ ] }:
    let
      unstablePkgs = import flake.inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      specialArgs = {
        inherit flake system;
        inherit (flake.inputs) secrets;
        unstablePkgs = unstablePkgs;
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
    in
    {
      inherit name;
      value = flake.inputs.nixpkgs.lib.nixosSystem {
        inherit specialArgs system;
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
