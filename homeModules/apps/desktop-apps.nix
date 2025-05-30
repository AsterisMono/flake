{
  pkgs,
  unstablePkgs,
  ...
}:
let
  extraPackages =
    with pkgs;
    [
      dbeaver-bin
      fractal
    ]
    ++ (with unstablePkgs; [
      code-cursor
      warp-terminal
      xpipe
      telegram-desktop
      obsidian
    ]);
in
{
  home.packages = extraPackages;

  programs.vscode = {
    enable = true;
    package = unstablePkgs.vscode.fhs;
  };

  programs.chromium = {
    enable = true;
    commandLineArgs = [
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"
      "--enable-wayland-ime"
    ];
  };

  programs.firefox = {
    enable = true;
    policies = {
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
          default_area = "menupanel";
        };
        "{3c078156-979c-498b-8990-85f7987dd929}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };
        "sponsorBlocker@ajay.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
          installation_mode = "force_installed";
          default_area = "menupanel";
        };
        "jid1-MnnxcxisBPnSXQ@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
          installation_mode = "force_installed";
          default_area = "menupanel";
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
          default_area = "menupanel";
        };
        "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
          installation_mode = "force_installed";
          default_area = "menupanel";
        };
        "queryamoid@kaply.com" = {
          install_url = "https://github.com/mkaply/queryamoid/releases/download/v0.1/query_amo_addon_id-0.1-fx.xpi";
          installation_mode = "force_installed";
          default_area = "menupanel";
        };
      };
      DisplayBookmarksToolbar = "never";
      DisablePocket = true;
      Homepage.StartPage = "previous-session";
      Preferences = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "gfx.webrender.all" = true;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
      };
      RequestedLocales = "zh-cn,zh,zh-tw,zh-hk,en-us,en";
    };
    profiles.default = {
      isDefault = true;
      name = "Brunette";
      userChrome = ''
        #TabsToolbar {
          display: none;
        }
        #sidebar-header {
          display: none;
        }
      '';
      search.force = {
        default = "Google";
        engines = {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };
        };
      };
    };
  };
}
