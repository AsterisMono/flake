{ osConfig, lib, ... }:
{
  options.amonoHome.hyprland = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = osConfig.programs.hyprland.enable;
      description = "是否启用 Hyprland 配置";
    };
  };
}
