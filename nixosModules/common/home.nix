{ config, lib, flake, username, ... }@homeInputs:
let
  cfg = config.amono.homeManager;
in
with lib;
{
  options = {
    amono.homeManager = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to use home-manager";
      };
      installGraphicalApps = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to install graphical apps in home-manager";
      };
    };
  };
  config = mkIf cfg.enable {
    home-manager = {
      users.${username}.imports = [
        flake.homeModules.common
        flake.homeModules.nixos
        flake.inputs.nix-index-database.hmModules.nix-index
      ];
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = ".bak";
      extraSpecialArgs = {
        inherit (homeInputs) flake system hostname username type unstablePkgs secrets;
      };
    };
  };
}
