{ lib, ... }:
{
  options.amono.desktop = {
    gpu = lib.mkOption {
      type = lib.types.enum [
        "intel"
        "nvidia"
        "amdgpu"
      ];
      default = "amdgpu";
      description = "GPU to use";
    };
    plasma.enable = lib.mkEnableOption "Enable KDE Plasma";
    gnome.enable = lib.mkEnableOption "Enable Gnome";
    hyprland.enable = lib.mkEnableOption "Enable Hyprland";
  };
}
