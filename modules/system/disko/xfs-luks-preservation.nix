{
  flake.diskoConfigurations.xfs-luks-preservation = {
    disko.devices = {
      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = [
          "defaults"
          "mode=755"
          "size=25%"
        ];
      };

      disk.main = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            persistent = {
              size = "100%";
              content = {
                type = "luks";
                name = "persistent";
                passwordFile = "/run/luks-password";
                settings.allowDiscards = true;
                content = {
                  type = "lvm_pv";
                  vg = "persistent";
                };
              };
            };
          };
        };
      };

      lvm_vg.persistent = {
        type = "lvm_vg";
        lvs = {
          nix = {
            size = "256G";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/nix";
              mountOptions = [
                "defaults"
                "pquota"
              ];
            };
          };
          state = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/persistent";
              mountOptions = [
                "defaults"
                "pquota"
              ];
            };
          };
        };
      };
    };

    fileSystems = {
      "/nix".neededForBoot = true;
      "/persistent".neededForBoot = true;
    };
  };
}
