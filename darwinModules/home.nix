{
  homeModules,
  username,
  inputs,
  ...
}@homeInputs:
{
  home-manager = {
    users.${username}.imports = [
      homeModules.common
      homeModules.darwin
      inputs.nix-index-database.hmModules.nix-index
    ];
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit (homeInputs)
        inputs
        system
        hostname
        unstablePkgs
        secrets
        ;
    };
  };
}
