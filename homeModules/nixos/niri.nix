{ config, lib, osConfig, pkgs, type, ... }:
let
  cfg = if type == "desktop" then osConfig.amono.desktop.niri.enable else false;
in
{
  config = lib.mkIf cfg {
    programs.fuzzel = {
      enable = true;
    };

    services.mako = {
      enable = true;
    };

    programs.niri.settings = {
      binds = {
        "Mod+D".action.spawn = "fuzzel";
        "Mod+Q".action.spawn = "kitty";
        "XF86AudioRaiseVolume".action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+" ];
        "XF86AudioLowerVolume".action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-" ];
        "Mod+Shift+E".action.quit.skip-confirmation = true;
      };
    };
  };
}
