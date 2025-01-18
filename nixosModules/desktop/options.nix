{ lib, ... }:
{
  options.amono.desktop = {
    suite = lib.mkOption {
      type = lib.types.enum [ "plasma" "hyprland" "gnome" "cosmic" ];
      default = "plasma";
      description = "Desktop suite to use";
    };
    gpu = lib.mkOption {
      type = lib.types.enum [ "intel" "nvidia" "amdgpu" ];
      default = "amdgpu";
      description = "GPU to use";
    };
    niri.enable = lib.mkEnableOption "Enable Niri";
  };
}
