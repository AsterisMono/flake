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
      # Hibernating to a swapfile needs a resume device and offset this machine
      # does not have, so only suspend is available. The power key falls back
      # to logind's default action.
      systemd.sleep.settings.Sleep.AllowHibernation = false;
    };
    # Kanshi matches this profile only when both heads are connected.
    # Workspace 1 stays on the Odyssey; one swaymsg assigns it before focusing.
    homeModule =
      { lib, pkgs, ... }:
      let
        swaymsg = lib.getExe' pkgs.unstable.swayfx "swaymsg";
        portrait = {
          criteria = "MKG MK-165Q32s 24G97P73LKZ4";
          status = "enable";
          mode = "2560x1440@165.003Hz";
          position = "0,0";
          scale = 1.0;
          transform = "90";
        };
        primary = {
          criteria = "Samsung Electric Company Odyssey G70D H1AK500000";
          status = "enable";
          mode = "3840x2160@143.988Hz";
          position = "1440,416";
          scale = 1.333333;
        };
        placePrimary = "${swaymsg} 'workspace 1 output \"${primary.criteria}\", focus output \"${primary.criteria}\"'";
      in
      {
        services.kanshi.settings = [
          {
            profile = {
              name = "desk";
              outputs = [
                portrait
                primary
              ];
              exec = placePrimary;
            };
          }
        ];
      };
  };
}
