{ flakeLib, nvimConfig, ... }:
let
  devRoles = flakeLib.collectFiles ./dev-roles;
  dev-base-env = flakeLib.collectFiles ./dev-base-env;
  customization = flakeLib.collectFiles ./customization;
in
{
  _module.args = {
    inherit nvimConfig;
  };

  imports = [
    ./nix-index.nix
    ./apps.nix
  ]
  ++ dev-base-env
  ++ devRoles
  ++ customization;

  programs.home-manager.enable = true;

  home.username = "cmiki";
  home.homeDirectory = "/home/cmiki";
  home.stateVersion = "23.05";
}
