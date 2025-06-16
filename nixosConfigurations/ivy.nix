{ nixosModules, ... }:
{
  imports = with nixosModules; [
    diskLayouts.simple
    roles.server
    services.proxy
    services.tailscale
    services.ssh
    users.cmiki
  ];

  systemd.network.networks."10-wired" = {
    matchConfig.Driver = "virtio_net";
    networkConfig = {
      DHCP = "no";
      Address = "192.168.31.101/24";
      Gateway = "192.168.31.1";
      DNS = "114.114.114.114";
    };
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  noa = {
    nix.enableUSTCSubstituter = true;
    tailscale.advertiseRoutes = [ "198.18.0.0/16" ];
    proxy.tunMode = true;
  };
}
