{
  flake.modules.nixos.boot-bios = {
    boot.loader.systemd-boot.enable = false;
    boot.loader.grub = {
      enable = true;
      efiSupport = false;
    };
  };
}
