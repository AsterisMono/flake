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
          users.cmiki.imports = [
            flake.homeModules.common
            flake.homeModules.nixos
            {
              home = {
                username = "cmiki";
                language.base = "zh_CN.UTF-8";
                stateVersion = "24.05";
                homeDirectory = "/home/cmiki";
              };
            }
          ];
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
          flake.inputs.home-manager-nixos.nixosModules.home-manager
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
