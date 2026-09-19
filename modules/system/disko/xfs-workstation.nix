{
  flake.diskoConfigurations.xfs-workstation = {
    # Swap sits at the end of the table so the root partition can grow into it
    # and the swap partition can be dropped without moving anything else. The
    # root partition ends 32G short of the disk, and disko creates the 100%
    # swap partition last, spanning what is left.
    disko.devices = {
      disk = {
        main = {
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
              root = {
                end = "-32G";
                content = {
                  type = "luks";
                  name = "root";
                  passwordFile = "/run/luks-password";
                  settings.allowDiscards = true;
                  content = {
                    type = "filesystem";
                    format = "xfs";
                    mountpoint = "/";
                    mountOptions = [
                      "defaults"
                      "pquota"
                    ];
                  };
                };
              };
              swap = {
                size = "100%";
                content = {
                  type = "swap";
                  resumeDevice = true;
                };
              };
            };
          };
        };
      };
    };
  };
}
