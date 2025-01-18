{ flake, config, lib, ... }:
let
  cfg = config.amono.desktop.niri.enable;
in
{
  config = lib.mkIf cfg {
    programs.niri.enable = true;
  };
}
