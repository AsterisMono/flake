{ isDesktop, flakeLib, nvimConfig, ... }: 
let
  commonModules = flakeLib.collectFiles ./modules/common;
  desktopModules = flakeLib.collectFiles ./modules/desktop;
  serverModules = flakeLib.collectFiles ./modules/server;
in
{
  _module.args = {
    inherit nvimConfig;
  };

  imports = commonModules ++ (if isDesktop then desktopModules else serverModules);

  programs.home-manager.enable = true;

  home.username = "cmiki";
  home.homeDirectory = "/home/cmiki";
  home.stateVersion = "23.05";
}
