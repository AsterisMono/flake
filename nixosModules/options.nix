{ lib, ... }:
with lib;
{
  options.amono = {
    desktop = {
      suite = mkOption {
        type = types.enum [ "plasma" "hyprland" ];
        default = "plasma";
        description = "Desktop suite to use";
      };
      gpu = mkOption {
        type = types.enum [ "intel" "nvidia" "amdgpu" ];
        default = "amdgpu";
        description = "GPU to use";
      };
    };
  };
}
