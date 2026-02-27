{
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  networking.useDHCP = false;
  networking.interfaces."enp6s18".ipv4.addresses = [
    {
      address = "154.12.191.17";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "193.41.250.250";
  networking.nameservers = [ "8.8.8.8" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
