{ inputs, ... }:
{
  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix/release-26.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.stylix =
    { pkgs, ... }:
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      stylix = {
        enable = true;
        image = pkgs.fetchurl {
          url = "https://r2.requiem.garden/kataomoi.jpg";
          hash = "sha256-1n30bVynUkK650sGyfmD9GoElzqxSUmSpfP7Tb9q2G4=";
        };
        base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-hard.yaml";
        cursor = {
          name = "macOS";
          package = pkgs.apple-cursor;
          size = 24;
        };
        icons = {
          enable = true;
          package = pkgs.la-capitaine-icon-theme;
          dark = "la-capitaine-icon-theme";
          light = "la-capitaine-icon-theme";
        };
        /*
          Stylix uses these as the primary fonts for application targets and
          inserts them into Fontconfig's default-font lists at order 600.
          modules/services/fonts.nix appends its `fallbackFonts` at order 1500
          through `lib.mkAfter`, producing this precedence:

            Stylix primary -> CJK fallback -> Nerd Font symbols -> emoji

          Keep Stylix's Fontconfig target enabled so the primary fonts remain
          synchronized with application-specific Stylix targets.
        */
        fonts = {
          serif = {
            name = "Noto Serif";
            package = pkgs.noto-fonts;
          };
          sansSerif = {
            name = "Noto Sans";
            package = pkgs.noto-fonts;
          };
          monospace = {
            name = "FiraCode Nerd Font";
            package = pkgs.nerd-fonts.fira-code;
          };
          emoji = {
            name = "Noto Color Emoji";
            package = pkgs.noto-fonts-color-emoji;
          };
          sizes = {
            terminal = 11;
          };
        };
        opacity.terminal = 0.80;
      };
    };

  flake.modules.homeManager.stylix = {
    stylix.targets = {
      firefox.enable = false;
      waybar = {
        addCss = false;
        opacity.enable = false;
      };
      zed.enable = false;
    };
  };
}
