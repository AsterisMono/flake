{ config, lib, ... }:
let
  cfg = config.amono.desktop.suite;
in
{
  config = lib.mkIf (cfg == "plasma") {
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
