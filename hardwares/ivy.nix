{
  pkgs,
  lib,
  assetsPath,
  ...
}:
# Taken from https://github.com/EHfive/flakes/blob/main/machines/r2s/configuration.nix. Thank you!
{
  hardware.deviceTree.name = "rockchip/rk3328-nanopi-r2s.dtb";

  # NanoPi R2S's DTS has not been actively updated, so just use the prebuilt one to avoid rebuilding
  hardware.deviceTree.package = lib.mkForce (
    pkgs.runCommand "dtbs-nanopi-r2s" { } ''
      install -TDm644 ${assetsPath}/r2s/rk3328-nanopi-r2s.dtb $out/rockchip/rk3328-nanopi-r2s.dtb
    ''
  );

  hardware.firmware = [
    (pkgs.runCommand "linux-firmware-r8152" { } ''
      install -TDm644 ${assetsPath}/r2s/rtl8153b-2.fw $out/lib/firmware/rtl_nic/rtl8153b-2.fw
    '')
  ];

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "ext4";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  boot = {
    loader = {
      timeout = 1;
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = lib.mkForce false;
      grub.enable = false;
      generic-extlinux-compatible = {
        enable = true;
        configurationLimit = 15;
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "console=ttyS2,1500000"
      "earlycon=uart8250,mmio32,0xff130000"
      "mitigations=off"
    ];
    blacklistedKernelModules = [
      "hantro_vpu"
      "drm"
      "lima"
      "rockchip_vdec"
    ];
    tmp.useTmpfs = true;
  };

  boot.initrd = {
    includeDefaultModules = false;
    kernelModules = [ "mmc_block" ];
    extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.haveged}/bin/haveged
    '';
    extraUtilsCommandsTest = ''
      $out/bin/haveged --version
    '';
    # provide entropy with haveged in stage 1 for faster crng init
    preLVMCommands = lib.mkBefore ''
      haveged --once
      # I don't need LVM
      alias lvm=true
    '';
  };

  boot.kernel.sysctl = {
    "vm.vfs_cache_pressure" = 10;
    "vm.dirty_ratio" = 50;
    "vm.swappiness" = 20;
  };

  powerManagement.cpuFreqGovernor = "schedutil";

  services.udev.extraRules =
    ''ACTION=="add" SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="8153", ''
    + ''RUN+="${pkgs.flakePackages.rtl8152-led-ctrl}/bin/rtl8152-led-ctrl set --device %s{busnum}:%s{devnum}"'';

  services.lvm.enable = false;

  systemd.services."wait-system-running" = {
    description = "Wait system running";
    serviceConfig = {
      Type = "simple";
    };
    script = ''
      systemctl is-system-running --wait
    '';
  };

  systemd.services."setup-net-leds" = {
    description = "Setup network LEDs";
    serviceConfig = {
      Type = "simple";
    };
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    script = ''
      ${pkgs.kmod}/bin/modprobe ledtrig_netdev
      cd /sys/class/leds/nanopi-r2s:green:wan
      echo netdev > trigger
      echo 1 | tee link tx rx >/dev/null
      echo end0 > device_name

      cd /sys/class/leds/nanopi-r2s:green:lan
      echo netdev > trigger
      echo 1 | tee link tx rx >/dev/null
      echo enu1 > device_name
    '';
  };
  systemd.services."setup-sys-led" = {
    description = "Setup booted LED";
    requires = [ "wait-system-running.service" ];
    after = [ "wait-system-running.service" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      echo default-on > /sys/class/leds/nanopi-r2s:red:sys/trigger
    '';
  };

  networking.useDHCP = false;

  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.Name = "enu1";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };
}
