{ inputs, ... }:
{
  flake.modules.aspects.workstation.imports = with inputs.self.modules.aspects; [
    audio
    bluetooth
    console
    fonts
    networkmanager
    plymouth
    podman
    power
    stylix
    u2f
    zswap

    _1password
    agents
    fcitx5
    firefox
    fish
    flatpak
    gdm
    git
    keyring
    kitty
    neovim
    netbird-desktop
    niri
    noctalia
    obsidian
    sing-box
    splayer-next
    starship
    udiskie
    unix-tools
    xpipe
    zed

    nvirellia
  ];

  flake.modules.nixos.workstation =
    { pkgs, ... }:
    {
      boot.kernelPackages = pkgs.linuxPackages_7_2;
      boot.loader.systemd-boot.configurationLimit = 5;
    };
}
