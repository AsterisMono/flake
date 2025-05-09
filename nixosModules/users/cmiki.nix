{
  pkgs,
  lib,
  config,
  inputs,
  homeModules,
  ...
}@homeInputs:
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
    # TODO: Change username
    users.users.cmiki = {
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
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMGPXhPWInP+CEc8wd+BWUiAqIAAIbF6rYuoZkt0QNiH"
      ];
    };

    programs.fish.enable = config.noa.homeManager.enable;

    home-manager = lib.mkIf config.noa.homeManager.enable {
      users.cmiki.imports = [
        inputs.nix-index-database.hmModules.nix-index
        homeModules.base
      ] ++ config.noa.homeManager.modules;
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = ".bak";
      extraSpecialArgs = {
        inherit (homeInputs)
          inputs
          system
          hostname
          unstablePkgs
          secrets
          ;
        inherit username;
      };
    };

    nix.settings.trusted-users = [ "username" ];
  };
}
