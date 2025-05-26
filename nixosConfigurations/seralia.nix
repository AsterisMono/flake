{
  nixosModules,
  ...
}:
{
  imports = with nixosModules; [
    server.base
    diskLayouts.btrfs
    tailscale
  ];

  disko.devices.disk.main.device = "/dev/vda";

  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
  ];

  services.k3s.enable = true;
  services.k3s.role = "server";
}
