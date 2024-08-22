{ lib, ... }:
with lib;
{
  options.amono = {
    homeManager = {
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
}
