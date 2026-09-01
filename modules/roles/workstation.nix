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

    _1password
    agents
    fcitx5
    firefox
    fish
    flatpak
    git
    kitty
    neovim
    netbird-ui
    plasma
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
}
