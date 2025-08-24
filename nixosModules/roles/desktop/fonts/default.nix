{ pkgs, ... }:
{
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      noto-fonts-cjk-serif
      noto-fonts-extra

      inter

      fira-code

      nerd-fonts.fira-code
      nerd-fonts.symbols-only
    ];

    enableGhostscriptFonts = true;
    enableDefaultPackages = true;

    fontconfig.defaultFonts = {
      serif = [
        "Noto Serif CJK SC"
        "Noto Serif"
        "Symbols Nerd Font"
        "Noto Color Emoji"
      ];
      sansSerif = [
        "Noto Sans CJK SC"
        "Noto Sans"
        "Symbols Nerd Font"
        "Noto Color Emoji"
      ];
      monospace = [
        "FiraCode Nerd Font Mono"
        "Noto Sans Mono CJK SC"
        "Symbols Nerd Font Mono"
        "Noto Color Emoji"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
