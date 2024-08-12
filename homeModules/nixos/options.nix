{ osConfig, lib, ... }:
with lib;
{
  options.amonoHome.hyprland = {
    enable = mkOption {
      type = types.bool;
      default = osConfig.programs.hyprland.enable;
      description = "是否启用 Hyprland 配置";
    };
  };
}
