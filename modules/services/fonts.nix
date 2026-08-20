{ lib, ... }:
let
  /*
    These lists intentionally omit the primary fonts selected in stylix.nix.
    Stylix inserts each primary into Fontconfig at order 600; `lib.mkAfter`
    assigns these entries order 1500, so they are consulted only after the
    primary font lacks a glyph. The name `fallbackFonts` reflects that role.

    Keep the entries ordered as CJK, Nerd Font symbols, then emoji. The same
    fallback order is applied to both NixOS and Home Manager Fontconfig.
  */
  fallbackFonts = {
    serif = lib.mkAfter [
      "Noto Serif CJK SC"
      "Symbols Nerd Font"
      "Noto Color Emoji"
    ];
    sansSerif = lib.mkAfter [
      "Noto Sans CJK SC"
      "Symbols Nerd Font"
      "Noto Color Emoji"
    ];
    monospace = lib.mkAfter [
      "Noto Sans Mono CJK SC"
      "Symbols Nerd Font Mono"
      "Noto Color Emoji"
    ];
  };
in
{
  flake.modules.nixos.fonts = { pkgs, ... }: {
    fonts = {
      fontDir.enable = true;
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        source-han-sans
        source-han-serif
        wqy_microhei
        inter

        fira-code
        maple-mono.NormalNL-NF
        nerd-fonts.fira-code

        nerd-fonts.symbols-only
      ];

      enableGhostscriptFonts = true;
      enableDefaultPackages = true;

      fontconfig.defaultFonts = fallbackFonts;
    };
  };

  flake.modules.homeManager.fonts.fonts.fontconfig = {
    enable = true;
    defaultFonts = fallbackFonts;
  };
}
