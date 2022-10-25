{ config, pkgs, ... }:

{
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji
      sarasa-gothic
      source-code-pro
      fira-code
    ];
  };

  fontconfig = {
    defaultFonts = {
      emoji = ["Noto Color Emoji"];
      monospace = [
        "Noto Sans Mono CJK SC"
        "DejaVu Sans Mono"
      ];
      sansSerif = [
        "Noto Sans CJK SC"
        "Source Han Sans SC"
      ];
      serif = [
        "Noto Serif CJK SC"
        "Source Han Serif SC"
      ];
    };
  };
}