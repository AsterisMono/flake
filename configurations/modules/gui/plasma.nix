{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
  };

  environment.systemPackages = with pkgs;[
    libsForQt5.yakuake
    kate
    materia-kde-theme
    papirus-icon-theme
    libsForQt5.qtstyleplugin-kvantum
  ];

  # home-manager.users.cmiki.programs.plasma = {
  #   shortcuts = {
  #     "code.desktop"."_launch" = "Meta+C";
  #     "firefox.desktop"."_launch" = "Meta+F";
  #     "yakuake"."toggle-window-state" = "F2";
  #   };

  #   files = {
  #     "kdeglobals"."KDE"."LookAndFeelPackage" = "com.github.varlesh.materia-dark";
  #     "kcminputrc"."Mouse"."cursorTheme" = "ePapirus";
  #     "kdeglobals"."KDE"."widgetStyle" = "kvantum-dark";
  #     "kwinrc"."org.kde.kdecoration2"."theme" = "Breeze 微风";
  #     "kwinrc"."org.kde.kdecoration2"."BorderSize" = "None";
  #   };
  # };

  # Kvantum config
  # This will not work DON'T COPY
  # home-manager.users.cmiki.xdg.dataFile.kvantum = {
  #   target = "Kvantum/kvantum.kvconfig";
  #   text = ''
  #     [General]
  #     theme=MateriaDark
  #   '';
  # };

  # Plasma配置：
  # 面板位置、信息
  # 快捷键
  # Dolphin双击打开
  # 电源管理（熄屏时间）
}
