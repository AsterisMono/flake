{ config, lib, flake, username, type, ... }@homeInputs:
let
  cfg = config.amono.homeManager;
in
{
  options = {
    amono.homeManager = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = type == "desktop";
        description = "Whether to use home-manager";
      };
      installGraphicalApps = lib.mkOption {
        type = lib.types.bool;
        default = type == "desktop";
        description = "Whether to install graphical apps in home-manager";
      };
    };
  };
  config = lib.mkIf cfg.enable {
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
