{
  lib,
  system,
  osConfig ? { },
  pkgs,
  assetsPath,
  ...
}:
let
  commonStylixPrefs = {
    enable = true;
    opacity.terminal = 0.95;
    fonts = {
      serif = {
        package = pkgs.noto-fonts-cjk-serif;
        name = "Noto Serif CJK SC";
      };
      sansSerif = {
        package = pkgs.noto-fonts-cjk-sans;
        name = "Noto Sans CJK SC";
      };
      monospace = {
        package = pkgs.nerd-fonts.fira-code;
        name = "FiraCode Nerd Font Mono";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
  darwinStylix = lib.recursiveUpdate commonStylixPrefs {
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
    overlays.enable = false;
    fonts.sizes = {
      terminal = 9;
      applications = 9;
    };
  };
  linuxStylix = lib.recursiveUpdate commonStylixPrefs {
    inherit (osConfig.stylix) base16Scheme;
    image = "${assetsPath}/wallpapers/rp-debian.jpg";
    cursor = {
      package = pkgs.capitaine-cursors;
      name = "capitaine-cursors";
      size = 32;
    };
    icons = {
      enable = true;
      package = pkgs.tela-icon-theme;
      dark = "Tela-dark";
      light = "Tela-light";
    };
  };
in
{
  stylix = if system == "aarch64-darwin" then darwinStylix else linuxStylix;
}
