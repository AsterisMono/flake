flake:
let
  mkDarwin = { hostname, username ? "cmiki", system ? "aarch64-darwin", customConfig ? { }, extraModules ? [ ] }:
    let
      unstablePkgs = import flake.inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      specialArgs = {
        inherit flake system hostname username unstablePkgs;
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
