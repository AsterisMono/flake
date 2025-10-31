{ pkgs, lib, ... }:
{
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      noto-fonts-cjk-serif
      noto-fonts-extra
      source-han-sans
      source-han-serif
      wqy_microhei

      inter

      fira-code

      nerd-fonts.fira-code
      nerd-fonts.symbols-only
    ];

    enableGhostscriptFonts = true;
    enableDefaultPackages = true;

    fontconfig.defaultFonts = {
      serif = lib.mkAfter [
        "Noto Serif"
        "Symbols Nerd Font"
        "Noto Color Emoji"
      ];
      sansSerif = lib.mkAfter [
        "Noto Sans"
        "Symbols Nerd Font"
        "Noto Color Emoji"
      ];
      monospace = lib.mkAfter [
        "Noto Sans Mono CJK SC"
        "Symbols Nerd Font Mono"
        "Noto Color Emoji"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
