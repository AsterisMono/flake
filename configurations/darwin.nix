flake:
let
  mkDarwin = { hostname, username ? "cmiki", system ? "aarch64-darwin", customConfig ? { }, extraModules ? [ ] }:
    let
      specialArgs = {
        inherit flake system hostname username;
      };
    in
    {
      name = hostname;
      value = flake.inputs.darwin.lib.darwinSystem {
        inherit specialArgs system;
        modules = [
          flake.darwinModules.darwin
          flake.inputs.home-manager-darwin.darwinModules.home-manager
        ] ++ extraModules;
      };
    };
in
builtins.listToAttrs (map mkDarwin [
  {
    hostname = "Oryx";
  }
])
