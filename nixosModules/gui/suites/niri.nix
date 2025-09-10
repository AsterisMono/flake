{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [ inputs.niri.nixosModules.niri ];

  niri-flake.cache.enable = false;

  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${lib.getExe pkgs.greetd.tuigreet} --cmd niri-session";
      };
    };
  };
}
