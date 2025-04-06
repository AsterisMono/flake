{
  lib,
  modulesPath,
  secrets,
  pkgs,
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

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # This really should be moved to elsewhere.
  services.github-runners = {
    picea = {
      enable = true;
      url = "https://github.com/AsterisMono/flake";
      tokenFile = secrets.flakeRunnerPAT;
      extraPackages = with pkgs; [
        deploy-rs
      ];
    };
  };
}
