{
  homeModules,
  inputs,
  lib,
  ...
}@osSpecialArgs:
let
  username = "cmiki";
in
{
  options = {
    noa.homeManager.modules = lib.mkOption {
      default = [ ];
      description = "Extra modules for home-manager";
    };
  };

  config = {
    # "Yes, I think the status quo is that you shouldn’t use the users.users.* arguments on your main user, but frankly I forget why."
    # https://github.com/LnL7/nix-darwin/issues/811
    users.users."${username}" = {
      home = "/Users/cmiki";
      description = "Noa Virellia";
    };

    home-manager = {
      sharedModules = [
        inputs.nix-index-database.homeModules.nix-index
        inputs.sops-nix.homeManagerModules.sops
      ];
      users."${username}".imports = [
        homeModules.base
      ];
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-bak";
      extraSpecialArgs = {
        inherit (osSpecialArgs)
          inputs
          system
          hostname
          unstablePkgs
          secretsPath
          assetsPath
          ;
        inherit username;
      };
    };

    nix.settings.trusted-users = [ username ];

    system.primaryUser = username;

    noa.homeManager.modules = with homeModules.apps; [
      shell-utils
      development
      desktop-apps
    ];
  };
}
