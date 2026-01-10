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
    extraFlags = [ "--disable traefik" ];
  };

  networking.firewall = {
    allowedTCPPorts = [
      6443
    ];
    trustedInterfaces = [
      "cni0"
      "flannel.1"
    ];
  };

  disko.devices.disk.main.device = "/dev/sda";
}
