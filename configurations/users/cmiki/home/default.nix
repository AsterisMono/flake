{ flakeLib, nvimConfig, ... }:
let
  devRoles = [
    ./dev-roles/nix-language.nix
  ];
  dev-base-env = flakeLib.collectFiles ./dev-base-env;
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
  ++ devRoles;

  programs.home-manager.enable = true;

  home.username = "cmiki";
  home.homeDirectory = "/home/cmiki";
  home.stateVersion = "23.05";
}
