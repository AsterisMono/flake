{ nixosModules, homeModules, ... }:
{
  imports = with nixosModules; [
    server.base
    diskLayouts.btrfs
    proxy
    tailscale
    users.cmiki
  ];

  disko.devices.disk.main.device = "/dev/sda";

  noa.homeManager.enable = true;
  noa.homeManager.modules = with homeModules; [
    apps.shell-utils
  ];
}
