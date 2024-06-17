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
