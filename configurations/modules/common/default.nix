{ ... }:

{
  imports =
    [
      ./boot.nix
      ./i18n.nix
      ./fonts.nix
      ./networking.nix
      ./nix-environment.nix
      ./security.nix
      ./base-packages.nix
    ];
}

