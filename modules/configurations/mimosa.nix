{ inputs, ... }: {
  flake.nixosConfigurations.mimosa = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = with inputs.self.modules.nixos; [
      system-server
      boot-efi
      inputs.self.diskoConfigurations.xfs-with-quota
      nix-substituter-cn
      services-podman
      services-sing-box
      services-netbird
      (
        {
          modulesPath,
          lib,
          config,
          ...
        }:
        {
          imports = [
            (modulesPath + "/installer/scan/not-detected.nix")
          ];

          networking = {
            hostName = "mimosa";
            domain = "lotus.local";
          };
          boot.initrd.availableKernelModules = [ "nvme" ];
          boot.initrd.kernelModules = [ "dm-snapshot" ];
          boot.kernelModules = [ "kvm-amd" ];
          boot.extraModulePackages = [ ];
          disko.devices.disk.main.device = "/dev/nvme0n1";

          nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
          hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        }
      )
    ];
  };
}
