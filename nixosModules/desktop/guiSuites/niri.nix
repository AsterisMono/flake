{
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.niri.nixosModules.niri ];

  niri-flake.cache.enable = false;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  services.xserver.displayManager.gdm = {
    enable = true;
  };
}
