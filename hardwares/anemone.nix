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
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_scsi"
    "virtio_blk"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Use GRUB2 as the boot loader.
  # We don't use systemd-boot because VMISS uses BIOS legacy boot.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    efiSupport = false;
  };

  networking.useDHCP = false;
  networking.interfaces."ens17".ipv4.addresses = [
    {
      address = "154.36.156.251";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "154.36.156.254";
  networking.nameservers = [ "8.8.8.8" ];
}
