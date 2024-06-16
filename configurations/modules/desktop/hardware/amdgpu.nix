{ config, pkgs, ... }:

{
  boot.initrd.kernelModules = [ "amdgpu" ];
  hardware.opengl = {
    # Mesa
    enable = true;
    # Vulkan
    driSupport = true;

    extraPackages = with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
}
