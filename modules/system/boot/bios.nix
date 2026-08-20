{
  flake.modules.nixos.bios = {
    boot.loader.systemd-boot.enable = false;
    boot.loader.grub = {
      enable = true;
      efiSupport = false;
    };
  };
}
