{ config, pkgs, lib, ... }:
let
  cfg = config.amono.desktop.gpu;
in
{
  config = lib.mkIf (cfg == "intel") {
    # Video acceleration
    hardware.opengl = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  };

}
