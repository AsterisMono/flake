{ lib, ... }:
with lib;
{
  options.amono.server = {
    proxy = {
      enable = mkEnableOption "Enable proxy";
    };
  };
}
