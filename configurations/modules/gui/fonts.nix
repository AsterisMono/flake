{ config, pkgs, lib, ... }:

{
  fonts = {
    fontDir.enable = true;
    fonts = (with pkgs; [
      (nerdfonts.override {
        fonts = [ "FiraCode" "Hack" "JetBrainsMono" "UbuntuMono" ];
      })
      hack-font
      inter
      liberation_ttf
      twemoji-color-font
      noto-fonts
      noto-fonts-emoji
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-extra
      roboto
      sarasa-gothic
      source-han-sans
      source-han-serif
      source-han-mono
      wqy_microhei
      wqy_zenhei
      meslo-lg
    ]);
    enableGhostscriptFonts = true;
    enableDefaultFonts = true;
    fontconfig = {
      enable = true;
      defaultFonts.emoji = [ "Twemoji" "Noto Color Emoji" ];
      defaultFonts.monospace = [ "SF Mono" "PingFang SC" "PingFang HK" "PingFang TC" ];
      defaultFonts.sansSerif = [ "SF Pro Text" "PingFang SC" "PingFang HK" "PingFang TC" ];
      defaultFonts.serif = [ "Noto Serif" "Noto Serif CJK SC" "Noto Serif CJK TC" "Noto Serif CJK JP" ];
    };
  };
}
