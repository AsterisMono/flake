{
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../diskLayouts/simple.nix
  ];

  boot.initrd.availableKernelModules = [
    "uhci_hcd"
    "ehci_pci"
    "ahci"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  swapDevices = [ ];

  networking = {
    useDHCP = false;
    interfaces.enp6s18.ipv4 = {
      addresses = [
        {
          address = "192.168.31.100";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = {
      address = "192.168.31.1";
      interface = "enp6s18";
    };
    nameservers = [ "114.114.114.114" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # This really, really shouldn't be here
  # TODO: Refactor
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
}
