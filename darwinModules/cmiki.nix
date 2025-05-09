{
  homeModules,
  inputs,
  ...
}@homeInputs:
{
  # "Yes, I think the status quo is that you shouldn’t use the users.users.* arguments on your main user, but frankly I forget why."
  # https://github.com/LnL7/nix-darwin/issues/811
  users.users.cmiki = {
    home = "/Users/cmiki";
    description = "Noa Virellia";
  };

  home-manager = {
    users.cmiki.imports = [
      inputs.nix-index-database.hmModules.nix-index
      homeModules.base
      homeModules.iterm2
      homeModules.apps.shell-utils
      homeModules.apps.development
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
      username = "cmiki";
    };
  };

  nix.settings.trusted-users = [ "cmiki" ];
}
