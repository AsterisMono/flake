{ flake, ... }:
let
  specialModules = [
    flake.inputs.nix-index-database.hmModules.nix-index
  ];
  modules = [
    ./modules/shell-apps.nix
    ./modules/git.nix
    ./modules/desktop-apps.nix
    ./modules/kitty
    ./modules/hyprland
  ] ++ specialModules;
in
{
  imports = modules;

  programs.home-manager.enable = true;

  home = {
    username = "cmiki";
    homeDirectory = "/home/cmiki";
    language.base = "zh_CN.UTF-8";
    stateVersion = "24.05";
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
