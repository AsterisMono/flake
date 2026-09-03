{ inputs, ... }:
let
  noctaliaGreeterTarget =
    {
      config,
      lib,
      options,
      ...
    }:
    {
      options.stylix.targets.noctalia-greeter.enable =
        config.lib.stylix.mkEnableTarget "Noctalia Greeter" true;

      config = lib.optionalAttrs (options.programs ? noctalia-greeter) (
        lib.mkIf
          (
            config.stylix.enable
            && config.stylix.targets.noctalia-greeter.enable
            && config.programs.noctalia-greeter.enable
          )
          {
            programs.noctalia-greeter.settings =
              let
                colors = config.lib.stylix.colors.withHashtag;
              in
              {
                appearance = {
                  scheme = "Synced";
                  scheme_selector_position = "hidden";
                  theme_mode = config.stylix.polarity;
                  font_family = config.stylix.fonts.sansSerif.name;

                  palette = {
                    primary = colors.base0D;
                    on_primary = colors.base00;
                    secondary = colors.base0E;
                    on_secondary = colors.base00;
                    tertiary = colors.base0B;
                    on_tertiary = colors.base00;
                    error = colors.base08;
                    on_error = colors.base00;
                    surface = colors.base00;
                    on_surface = colors.base05;
                    surface_variant = colors.base01;
                    on_surface_variant = colors.base04;
                    outline = colors.base03;
                    shadow = colors.base00;
                    hover = colors.base0C;
                    on_hover = colors.base00;
                  };

                  wallpaper = {
                    path = toString config.stylix.image;
                    fill_mode = "crop";
                  };
                };

                cursor = {
                  theme = config.stylix.cursor.name;
                  size = config.stylix.cursor.size;
                  path = "${config.stylix.cursor.package}/share/icons";
                };
              };
          }
      );
    };
in
{
  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix/release-26.05";
    inputs.flake-parts.follows = "flake-parts";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.systems.follows = "systems";
  };

  flake.modules.nixos.stylix =
    { pkgs, ... }:
    {
      imports = [
        inputs.stylix.nixosModules.stylix
        noctaliaGreeterTarget
      ];

      stylix = {
        enable = true;
        image = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/linuxdotexe/nordic-wallpapers/refs/heads/master/wallpapers/ign_unsplash3.png";
          hash = "sha256-mEjpLq0pE+3UNdg2S1Yjrgx24WoqqMUXW40GL/m9Ltk=";
        };
        base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
        polarity = "dark";
        cursor = {
          name = "macOS";
          package = pkgs.apple-cursor;
          size = 24;
        };
        icons = {
          enable = true;
          package = pkgs.tela-icon-theme;
          dark = "Tela-dark";
          light = "Tela-dark";
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
            name = "Twitter Color Emoji";
            package = pkgs.twitter-color-emoji;
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
