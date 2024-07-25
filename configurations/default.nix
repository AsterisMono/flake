flake:
# home manager modules and nixos modules implictly receive specialArgs: flake.
let
  nixosModules = flake.lib.collectFiles ../nixosModules;
  homeModules = flake.lib.collectFiles ../homeModules;
  unstablePkgs = import flake.inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  homeModule = {
    home-manager = {
      users.cmiki.imports = homeModules;
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = ".bak";
      extraSpecialArgs = {
        inherit flake unstablePkgs;
        inherit (flake.inputs) secrets;
      };
    };
  };
  mkLinux = { name, customConfig ? { }, extraModules ? [ ] }:
    {
      inherit name;
      value = flake.inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit flake unstablePkgs;
          inherit (flake.inputs) secrets;
        };
        modules = [
          ./hardwares/${name}.nix
          flake.inputs.nur.nixosModules.nur
          flake.inputs.disko.nixosModules.disko
          flake.inputs.home-manager.nixosModules.home-manager
          homeModule
          { networking.hostName = name; }
          { config.amono = customConfig; }
        ] ++ extraModules ++ nixosModules;
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
