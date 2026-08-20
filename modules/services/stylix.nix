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
        opacity.terminal = 0.70;
      };
    };

  flake.modules.homeManager.stylix = {
    stylix.targets = {
      firefox = {
        profileNames = [ "default" ];
        colorTheme.enable = true;
      };
      waybar = {
        addCss = false;
        colors.enable = true;
        fonts.enable = true;
        opacity.enable = false;
      };
      zed.enable = false;
    };

    programs.firefox.profiles.default = {
      # Profile-installed extensions are disabled on first discovery unless
      # this scope is trusted. Firefox Color must run once to apply the Stylix
      # theme stored below.
      settings."extensions.autoDisableScopes" = 0;

      # Applying Firefox Color writes managed extension storage. Home Manager
      # requires this per-extension acknowledgement before replacing old theme
      # state left in an existing profile.
      extensions.settings."FirefoxColor@mozilla.com".force = true;
    };
  };
}
