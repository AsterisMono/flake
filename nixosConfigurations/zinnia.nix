{
  nixosModules,
  homeModules,
  ...
}:
{
  imports = with nixosModules; [
    diskLayouts.btrfs
    proxy
    tailscale
    users.cmiki
    desktop.base
    desktop.guiSuites.gnome
    server.ssh
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
