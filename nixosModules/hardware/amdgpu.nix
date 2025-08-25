{
  pkgs,
  ...
}:
{
  boot.initrd.kernelModules = [ "amdgpu" ];
  hardware.graphics = {
    enable = true;

    extraPackages = with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
}
