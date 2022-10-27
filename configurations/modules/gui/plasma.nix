{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
  };

  environment.systemPackages = [
    pkgs.libsForQt5.yakuake
  ];

  # Plasma配置：
  # 面板位置、信息
  # 快捷键
  # Dolphin双击打开
  # 电源管理（熄屏时间）
}
