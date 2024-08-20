flake:
let
  mkDarwin = { hostname, username ? "cmiki", system ? "aarch64-darwin", customConfig ? { }, extraModules ? [ ] }:
    let
      specialArgs = {
        inherit flake system hostname username;
      };
      homeModule = {
        home-manager = {
          users.${username}.imports = [
            flake.homeModules.common
            flake.homeModules.darwin
            flake.inputs.nix-index-database.hmModules.nix-index
          ];
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = specialArgs;
        };
      };
    in
    {
      name = hostname;
      value = flake.inputs.darwin.lib.darwinSystem {
        inherit specialArgs system;
        modules = [
          flake.darwinModules.darwin
          flake.inputs.home-manager-darwin.darwinModules.home-manager
          homeModule
        ] ++ extraModules;
      };
    };
in
builtins.listToAttrs (map mkDarwin [
  {
    hostname = "Oryx";
  }
])
