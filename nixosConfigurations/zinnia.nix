{
  nixosModules,
  homeModules,
  ...
}:
{
  imports = with nixosModules; [
    roles.server
    diskLayouts.btrfs
    services.proxy
    services.tailscale
    services.ssh
    users.cmiki
  ];

  disko.devices.disk.main.device = "/dev/sda";

  noa = {
    nix.enableUSTCSubstituter = true;
    homeManager.enable = true;
    homeManager.modules = with homeModules; [
      apps.shell-utils
      apps.development
    ];
  };
}
