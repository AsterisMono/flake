{ inputs, ... }:
{
  flake.modules.aspects.workstation.imports = with inputs.self.modules.aspects; [
    audio
    bluetooth
    fonts
    networkmanager
    podman
    power
    stylix
    u2f

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
    sing-box
    starship
    sway
    unix-tools
    vicinae
    waybar
    xpipe
    zed

    nvirellia
  ];

  flake.modules.nixos.workstation.boot.loader.systemd-boot.configurationLimit = 5;
}
