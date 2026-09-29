{ inputs, ... }:
{
  machines.asymmetry = {
    system = "x86_64-linux";
    imports = with inputs.self.modules.aspects; [
      base
      workstation
      efi
      secure-boot
      i18n
      substituter-cn
    ];
    diskoConfig = inputs.self.diskoConfigurations.xfs-workstation;
    hardware =
      {
        config,
        lib,
        modulesPath,
        ...
      }:
      {
        imports = [
          (modulesPath + "/installer/scan/not-detected.nix")
        ];

        boot = {
          initrd.availableKernelModules = [
            "xhci_pci"
            "thunderbolt"
            "nvme"
            "usbhid"
            "usb_storage"
            "sd_mod"
          ];
          initrd.kernelModules = [ ];
          kernelModules = [ "kvm-intel" ];
          extraModulePackages = [ ];
        };

        networking = {
          hostName = "asymmetry";
          domain = "lotus.local";
        };

        disko.devices.disk.main.device = "/dev/disk/by-id/nvme-YMTC_YMSS2CD08D25MC_YMB51T0JA25495102F";

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
        hardware.cpu.intel = {
          npu.enable = true;
          updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        };
      };
    homeModule = {
      programs.niri.settings.outputs."China Star Optoelectronics Technology Co., Ltd MNE007ZA3-4 Unknown" =
        {
          mode = {
            width = 2880;
            height = 1800;
            refresh = 120.0;
          };
          scale = 1.75;
          variable-refresh-rate = "on-demand";
        };
    };
  };
}
