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
    desktop.guiSuites.niri
    desktop.hardware.bluetooth
    services.proxy
    services.tailscale
    users.cmiki
  ];

  disko.devices.disk.main.device = "/dev/nvme0n1";

  noa = {
    nix.enableMirrorSubstituter = true;
    homeManager = {
      enable = true;
      modules = with homeModules; [
        apps.shell-utils
        apps.desktop-apps
        apps.development
        niri
      ];
    };
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
