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
  networking.useNetworkd = true;

  systemd.network.networks."10-enp6s18" = {
    matchConfig.MACAddress = "6e:6f:b6:ee:c9:b8";
    address = [
      "154.12.191.17/32"
    ];
    routes = [
      {
        Gateway = "193.41.250.250";
        GatewayOnLink = true;
      }
    ];
    networkConfig.DNS = [ "8.8.8.8" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
