{ nixosModules, ... }:
{
  imports = with nixosModules; [
    server.base
    diskLayouts.simple
    proxy
    tailscale
    users.cmiki
  ];

  networking = {
    useDHCP = false;
    interfaces.enp6s18.ipv4.addresses = [
      {
        address = "192.168.31.100";
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      address = "192.168.31.1";
      interface = "enp6s18";
    };
    nameservers = [ "114.114.114.114" ];
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  noa = {
    nix.enableUSTCSubstituter = true;
    tailscale.advertiseRoutes = [ "198.18.0.1/16" ];
    proxy.tunMode = true;
  };
}
