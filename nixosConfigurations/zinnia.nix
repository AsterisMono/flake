{
  nixosModules,
  homeModules,
  ...
}:
{
  imports = with nixosModules; [
    roles.desktop
    diskLayouts.btrfs
    services.proxy
    services.tailscale
    services.ssh
    users.cmiki
    desktop.guiSuites.gnome
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
