{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.amono.desktop.gpu;
in
{
  config = lib.mkIf (cfg == "intel") {
    # Video acceleration
    hardware.graphics = {
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
