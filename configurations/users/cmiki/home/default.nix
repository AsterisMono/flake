{ isDesktop, flake, nvimConfig, ... }: 
let
  specialModules = [
    flake.inputs.nix-index-database.hmModules.nix-index
  ];
  modules = ( flake.lib.collectFiles ./modules ) ++ specialModules;
in
{
  _module.args = {
    inherit nvimConfig;
  };

  imports = modules;

  programs.home-manager.enable = true;

  home.username = "cmiki";
  home.homeDirectory = "/home/cmiki";
  home.stateVersion = "24.05";
}
