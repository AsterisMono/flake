{
  nixosModules,
  ...
}:
{
  imports = with nixosModules; [
    roles.server
    diskLayouts.gpt-bios-compat-swap
  ];

  services.k3s = {
    enable = true;
    role = "server";
  };

  networking.firewall.allowedTCPPorts = [
    6443
  ];

  disko.devices.disk.main.device = "/dev/sda";
}
