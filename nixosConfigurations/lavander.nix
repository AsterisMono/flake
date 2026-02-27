{
  nixosModules,
  ...
}:
{
  # Lavander - unintended purple

  imports = with nixosModules; [
    roles.server
    diskLayouts.gpt-bios-compat
    users.cmiki
    users.sugar
  ];

  disko.devices.disk.main.device = "/dev/vda";
}
