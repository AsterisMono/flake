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
    gui.suites.sway
    gui.stylix
    hardware.bluetooth
    hardware.intel-graphics
    services.flatpak
    services.proxy
    services.podman
    users.cmiki
  ];

  disko.devices.disk.main.device = "/dev/nvme0n1";

  noa = {
    nix.enableMirrorSubstituter = true;
    homeManager = {
      enable = true;
      modules = with homeModules; [
        linux-desktop
        guiSuites.sway
        apps.shell-utils
        apps.development
      ];
    };
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
