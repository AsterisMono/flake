{ config, lib, flake, ... }:
let
  cfg = config.amono.desktop.suite;
in
{
  config = lib.mkIf (cfg == "cosmic") {
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;
  };
}
