{ ... }:
{
  imports = [
    ./git.nix
    ./nix-index.nix
    ./helix.nix
  ];

  programs.home-manager.enable = true;

  home.username = "cmiki";
  home.homeDirectory = "/home/cmiki";
  home.stateVersion = "23.05";
}
