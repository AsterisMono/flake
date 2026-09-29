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
      # Hibernating to a swapfile needs a resume device and offset this machine
      # does not have, so only suspend is available. Niri handles the power key
      # by sleeping.
      systemd.sleep.settings.Sleep.AllowHibernation = false;
    };
    # Workspace 1 stays on the Odyssey.
    homeModule = {
      programs.niri.settings = {
        outputs = {
          "MKG MK-165Q32s 24G97P73LKZ4" = {
            mode = {
              width = 2560;
              height = 1440;
              refresh = 165.003;
            };
            position = {
              x = 0;
              y = 0;
            };
            scale = 1.0;
            transform.rotation = 270;
            variable-refresh-rate = "on-demand";
          };
          "Samsung Electric Company Odyssey G70D H1AK500000" = {
            mode = {
              width = 3840;
              height = 2160;
              refresh = 120.0;
            };
            position = {
              x = 1440;
              y = 416;
            };
            scale = 1.333333;
            variable-refresh-rate = "on-demand";
            focus-at-startup = true;
          };
        };
        workspaces."1".open-on-output = "Samsung Electric Company Odyssey G70D H1AK500000";
      };
    };
  };
}
