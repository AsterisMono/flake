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

  noa = {
    nix.enableUSTCSubstituter = true;
    homeManager.enable = true;
    homeManager.modules = with homeModules; [
      apps.shell-utils
    ];
  };

  # For VSCode Remote SSH
  programs.nix-ld.enable = true;
}
