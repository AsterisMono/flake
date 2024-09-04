{ flake, username, ... }@homeInputs:
{
  home-manager = {
    users.${username}.imports = [
      flake.homeModules.common
      flake.homeModules.darwin
      flake.inputs.nix-index-database.hmModules.nix-index
    ];
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit (homeInputs) flake system hostname username type unstablePkgs secrets;
    };
  };
}
