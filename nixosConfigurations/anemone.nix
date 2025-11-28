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

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [
      80
      443
    ];
  };

  disko.devices.disk.main.device = "/dev/vda";
}
