{
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.niri.nixosModules.niri ];

  niri-flake.cache.enable = false;

  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  services.xserver.displayManager.gdm.enable = true;
}
