{
  pkgs,
  unstablePkgs,
  system,
  lib,
  ...
}:
let
  isDarwin = system == "aarch64-darwin";
  homePackages = with unstablePkgs; [
    dbeaver-bin
    telegram-desktop
    obsidian
    bitwarden-desktop
    slack
  ];
  darwinOnlyPackages = with unstablePkgs; [
    ice-bar
    google-chrome # chromium is not available on darwin
    alt-tab-macos
    maccy
    shottr
    raycast
    rectangle
    ice-bar
    insomnia
    stats
    chatgpt
    pkgs.tailscale
    pkgs.flakePackages.orbstack
  ];
in
{
  home.packages = homePackages ++ lib.optionals isDarwin darwinOnlyPackages;

  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    package = if isDarwin then unstablePkgs.ghostty-bin else unstablePkgs.ghostty;
  };

  xdg.configFile."ghostty/config".source = ./ghostty.config;

  programs.vscode = {
    enable = true;
    package = if isDarwin then unstablePkgs.vscode else unstablePkgs.vscode-fhs;
  };

  programs.chromium = {
    enable = !isDarwin;
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
        "{d3598eb6-77e5-4fa8-b137-8b6b0d687560}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/minimalist-ros%C3%A9-pine/latest.xpi";
          installation_mode = "force_installed";
        };
        "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/refined-github-/latest.xpi";
          installation_mode = "force_installed";
          default_area = "menupanel";
        };
        "jid1-BoFifL9Vbdl2zQ@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/decentraleyes/latest.xpi";
          installation_mode = "force_installed";
          default_area = "menupanel";
        };
        "{74145f27-f039-47ce-a470-a662b129930a}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/clearurls/latest.xpi";
          installation_mode = "force_installed";
          default_area = "menupanel";
        };
      };
      DisplayBookmarksToolbar = "never";
      DisablePocket = true;
      OfferToSaveLogins = false;
      PasswordManagerEnabled = false;
      Homepage.StartPage = "previous-session";
      Preferences = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.ctrlTab.sortByRecentlyUsed" = true;
      }
      // lib.optionalAttrs (!isDarwin) {
        "media.ffmpeg.vaapi.enabled" = true;
        "gfx.webrender.all" = true;
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

  # fcitx5 config
  xdg.configFile."fcitx5".source = ./fcitx5;
}
