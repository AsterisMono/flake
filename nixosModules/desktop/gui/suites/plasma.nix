{ config, lib, ... }:
let
  cfg = config.amono.desktop.plasma.enable;
in
{
  config = lib.mkIf cfg {
    services = {
      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
        };
      };
      desktopManager.plasma6.enable = true;
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };
}
