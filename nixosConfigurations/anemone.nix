{
  nixosModules,
  ...
}:
{
  # Anemone (JP.TKY.TRI.Core)

  imports = with nixosModules; [
    roles.server
    diskLayouts.gpt-bios-compat
    services.tailscale
    services.docker
  ];

  disko.devices.disk.main.device = "/dev/vda";
}
