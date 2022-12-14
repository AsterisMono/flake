{ config, pkgs, ... }: {
  # TODO: Simplify
  home-manager.users.cmiki.programs.firefox = {
    enable = true;
    package = pkgs.firefox.override {
      extraPolicies = {
        PasswordManagerEnabled = true;
        DisableFirefoxAccounts = true;
        DisablePocket = true;
        ExtensionUpdate = false;
        FirefoxHome = {
          Pocket = false;
          Snippets = false;
        };
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        UserMessaging = {
          ExtensionRecommendations = false;
          SkipOnboarding = true;
        };
      };
      extraPrefs = ''
        lockPref("browser.newtabpage.activity-stream.feeds.topsites", false);
        lockPref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
        lockPref("security.identityblock.show_extended_validation", true);
      '';
    };
    # Profiles
    profiles = {
      default = {
        name = "Chatnoir Miki";
        search.engines = {
          "Nix Packages" = {
            urls = [{
              template = "https://search.nixos.org/packages";
              params = [
                { name = "channel"; value = "unstable"; }
                { name = "type"; value = "packages"; }
                { name = "query"; value = "{searchTerms}"; }
              ];
            }];

            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };

          "Nix Options" = {
            urls = [{
              template = "https://search.nixos.org/options";
              params = [
                { name = "channel"; value = "unstable"; }
                { name = "type"; value = "packages"; }
                { name = "query"; value = "{searchTerms}"; }
              ];
            }];

            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@no" ];
          };

          "Home-manager Options" = {
            urls = [{
              template = "https://mipmip.github.io/home-manager-option-search/?{searchTerms}";
            }];

            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@hm" ];
          };
        };
        search.default = "Google";
        search.force = true;
        settings = {
          "app.update.auto" = false;
          "fission.autostart" = true;
          "media.ffmpeg.vaapi.enabled" = true;
          "media.rdd-ffmpeg.enabled" = true;
          # Force enable account containers
          "privacy.userContext.enabled" = true;
          "privacy.userContext.ui.enabled" = true;
          "toolkit.legacyUserProfileCustomizations.stylesheets
" = true;
          "intl.locale.requested" = "zh-CN,en_US";
          "browser.search.region" = "GB";
          "browser.tabs.inTitlebar" = 1;
        };
        userChrome = builtins.readFile
          ./userChrome.css;
      };
    };
    # Firefox extensions
    # TODO: Add links to https://addons.mozilla.org
    extensions = with config.nur.repos.rycee.firefox-addons;
      [
        octotree
        auto-tab-discard
        decentraleyes
        sidebery
        wappalyzer
        # switchyomega
        plasma-integration
        form-history-control
        add-custom-search-engine
      ] ++
      (
        let
          extra-addons = pkgs.callPackage ./extra-addons.nix {
            buildFirefoxXpiAddon =
              config.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon;
          };
        in
        with extra-addons; [
          i-still-dont-care-about-cookies
          vimium-ff
        ]
      );
  };
}
