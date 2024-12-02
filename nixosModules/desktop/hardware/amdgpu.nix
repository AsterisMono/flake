{ config, pkgs, lib, ... }:
let
  cfg = config.amono.desktop.gpu;
in
{
  config = lib.mkIf (cfg == "amdgpu") {
    boot.initrd.kernelModules = [ "amdgpu" ];
    hardware.graphics = {
      enable = true;

      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  };
}
