{ inputs, ... }:
{
  machines.asymmetry = {
    system = "x86_64-linux";
    imports = with inputs.self.modules.aspects; [
      base
      workstation
      efi
      i18n
      substituter-cn
    ];
    diskoConfig = inputs.self.diskoConfigurations.xfs-with-quota;
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

        disko.devices.disk.main.device = "/dev/nvme0n1";

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
        hardware.cpu.intel = {
          npu.enable = true;
          updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        };

        hardware.sensors.cpuTemperature = {
          hwmonPathAbs = "/sys/devices/platform/coretemp.0/hwmon";
          inputFilename = "temp1_input";
        };
      };
  };
}
