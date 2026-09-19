{ inputs, ... }:
{
  machines.parallax = {
    system = "x86_64-linux";
    imports = with inputs.self.modules.aspects; [
      base
      workstation
      efi
      nvidia
      hmcl
      steam
      zswap
      i18n
      substituter-cn
    ];
    diskoConfig = inputs.self.diskoConfigurations.workstation-legacy;
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
            "nvme"
            "xhci_pci"
            "ahci"
            "usbhid"
            "usb_storage"
          ];
          initrd.kernelModules = [ ];
          kernelModules = [ "kvm-amd" ];
          extraModulePackages = [ ];
        };

        networking = {
          hostName = "parallax";
          domain = "lotus.local";
        };

        disko.devices.disk.main.device = "/dev/disk/by-id/nvme-ZHITAI_Ti600_1TB_ZTA601TAB240960FR7";

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
        hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

        hardware.sensors.cpuTemperature = {
          hwmonPathAbs = "/sys/devices/pci0000:00/0000:00:18.3/hwmon";
          inputFilename = "temp1_input";
        };
      };
    nixosModule = {
      boot.kernelParams = [
        "video=HDMI-A-1:3840x2160@60"
        "video=DP-3:2560x1440@60,rotate=90"
      ];
      swapDevices = [
        {
          device = "/swapfile";
          size = 32 * 1024;
          priority = 10;
        }
      ];
      services.logind.settings.Login.HandlePowerKey = "hibernate";
    };
    homeModule = {
      wayland.windowManager.sway.config = {
        output = {
          "Invalid Vendor Codename - RTK HDMI 0x01010101".disable = "";
          "MKG MK-165Q32s 24G97P73LKZ4" = {
            mode = "2560x1440@165.003Hz";
            position = "0 0";
            scale = "1";
            transform = "90";
          };
          "Samsung Electric Company Odyssey G70D H1AK500000" = {
            mode = "3840x2160@143.988Hz";
            position = "1440 416";
            scale = "1.333333";
          };
        };
        startup = [
          {
            command = ''swaymsg focus output "Samsung Electric Company Odyssey G70D H1AK500000"'';
          }
        ];
        workspaceOutputAssign = [
          {
            workspace = "1";
            output = "Samsung Electric Company Odyssey G70D H1AK500000";
          }
        ];
      };
    };
  };
}
