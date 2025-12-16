{
  nixosModules,
  homeModules,
  ...
}:
{
  # Azura - the still heart beneath the storm

  imports = with nixosModules; [
    roles.desktop
    diskLayouts.btrfs
    gui.suites.plasma
    gui.stylix
    gui.flatpak
    hardware.bluetooth
    services.proxy
    services.tailscale
    services.docker
    users.cmiki
  ];

  disko.devices.disk.main.device = "/dev/nvme0n1";

  noa = {
    nix.enableMirrorSubstituter = true;
    homeManager = {
      enable = true;
      modules = with homeModules; [
        linux-desktop
        apps.shell-utils
        apps.development
      ];
    };
    docker.useRegistryMirror = true;
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
