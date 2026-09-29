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
        "video=DP-1:3840x2160@60"
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
    homeModule =
      { lib, ... }:
      {
        programs.niri.settings = {
          # Matched by connector name, the same identifiers the kernel params
          # below use; the EDID descriptions the kanshi profiles used did not
          # match in niri. Refresh stays unset so niri picks the highest rate
          # the link advertises for the resolution.
          outputs."DP-1" = {
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
          workspaces."1".open-on-output = "DP-1";
        };

        # niri-flake's output schema has no per-output `layout` override, so
        # the portrait monitor's whole output block is raw KDL: one window
        # fills its width instead of the global half.
        programs.niri.config = lib.mkOptionDefault [
          (inputs.niri.lib.kdl.node "output" "DP-3" [
            (inputs.niri.lib.kdl.leaf "mode" "2560x1440")
            (inputs.niri.lib.kdl.leaf "scale" 1.0)
            (inputs.niri.lib.kdl.leaf "transform" "270")
            (inputs.niri.lib.kdl.leaf "position" {
              x = 0;
              y = 0;
            })
            (inputs.niri.lib.kdl.leaf "variable-refresh-rate" { on-demand = true; })
            (inputs.niri.lib.kdl.node "layout"
              [ ]
              [
                (inputs.niri.lib.kdl.node "default-column-width"
                  [ ]
                  [
                    (inputs.niri.lib.kdl.leaf "proportion" 1.0)
                  ]
                )
              ]
            )
          ])
        ];
      };
  };
}
