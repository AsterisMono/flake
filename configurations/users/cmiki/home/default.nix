{ pkgs, ... }:

{
  home-manager.users.cmiki.imports = 
    let
      modules = flakeLib.collectFiles ./modules;
    in
    {
      _module.args = {
        inherit nvimConfig;
      };

      imports = modules;

      programs.home-manager.enable = true;

      home.username = "cmiki";
      home.homeDirectory = "/home/cmiki";
      home.stateVersion = "23.05";
    }
}
