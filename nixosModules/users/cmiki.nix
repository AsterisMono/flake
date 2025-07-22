{
  pkgs,
  lib,
  config,
  inputs,
  homeModules,
  ...
}@osSpecialArgs:
let
  username = "cmiki";
in
{
  options = {
    noa.homeManager = {
      enable = lib.mkEnableOption "Enable home-manager for Noa Virellia.";
      modules = lib.mkOption {
        default = [ ];
        description = "Extra modules for home-manager";
      };
    };
  };

  config = {
    users.users."${username}" = {
      isNormalUser = true;
      description = "Noa Virellia";
      extraGroups = [
        "wheel"
        "video"
        "docker"
        "networkmanager"
        "input"
        "wireshark"
      ];
      shell = if config.noa.homeManager.enable then pkgs.fish else pkgs.bashInteractive;
      initialHashedPassword = "$y$j9T$Or7mqutFE5iEFtJb4QmdR1$N0yuyRzIOavwnsnrkK4yR5Msg1oQ0RAXpKVN/LpV3p.";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOOz0CMmkGSXv4H77rmrmvadltAlwAZeVimxGoUAfArs"
      ];
    };

    programs.fish.enable = config.noa.homeManager.enable;

    home-manager = lib.mkIf config.noa.homeManager.enable {
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
          ;
        inherit username;
      };
    };

    nix.settings.trusted-users = [ username ];
  };
}
