_: {
  flake.modules.homeManager.firefox = { pkgs, lib, ... }: {
    programs.firefox = {
      enable = true;
      package = pkgs.unstable.firefox;
      policies = {
        ExtensionSettings =
          lib.mapAttrs
            (
              _: value:
              {
                installation_mode = "force_installed";
                default_area = "menupanel";
              }
              // value
            )
            {
              "uBlock0@raymondhill.net" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              };
              "{3c078156-979c-498b-8990-85f7987dd929}" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi";
                default_area = "navbar";
              };
              "sponsorBlocker@ajay.app" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
              };
              "jid1-MnnxcxisBPnSXQ@jetpack" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
              };
              "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
              };
              "queryamoid@kaply.com" = {
                install_url = "https://github.com/mkaply/queryamoid/releases/download/v0.1/query_amo_addon_id-0.1-fx.xpi";
              };
              "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/refined-github-/latest.xpi";
              };
              "jid1-BoFifL9Vbdl2zQ@jetpack" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/decentraleyes/latest.xpi";
              };
              "{74145f27-f039-47ce-a470-a662b129930a}" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/clearurls/latest.xpi";
              };
              "chrome-mask@overengineer.dev" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/chrome-mask/latest.xpi";
              };
              "redirect-nix-wiki@undesided.me" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/redirectnixwiki/latest.xpi";
              };
              "{eceab40b-230a-4560-98ed-185ad010633f}" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/nixos-packages-search-engine/latest.xpi";
              };
              "{39ba6e88-6981-4e1f-9c68-591c9965633b}" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/nixos-options-search-engine/latest.xpi";
              };
              "Tab-Session-Manager@sienori" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/tab-session-manager/latest.xpi";
              };
              "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
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
          "media.ffmpeg.vaapi.enabled" = true;
          "gfx.webrender.all" = true;
          "media.hardware-video-decoding.force-enabled" = true;
          # Firefox paints an opaque backplate behind the window and another
          # one behind the sidebar's browser, and SwayFX only blurs what a
          # window leaves transparent, so the chrome can only become glass once
          # Firefox stops forcing those backgrounds. The pref covers sidebar
          # browsers as well, which is what lets Sidebery join in.
          "browser.tabs.allow_transparent_browser" = true;
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

          /* Glass chrome. Firefox paints the window and the chrome with theme
           * colours before the toolbox, the bars and the sidebar draw on top,
           * and SwayFX blurs only what a window leaves transparent. Clearing
           * the window and the containers between the bars therefore opens the
           * blur, while the bars themselves keep one tint each so the chrome
           * reads as a single material over the wallpaper instead of a stack
           * of half-transparent layers.
           */
          :root {
            /* Both sidebar implementations paint from this token, including the
             * shadow trees the selectors below cannot reach. */
            --sidebar-background-color: transparent !important;
            --sidebar-box-background: transparent !important;
          }

          :root,
          body,
          #navigator-toolbox,
          #browser,
          #sidebar,
          .sidebar-browser-stack,
          sidebar-main,
          #sidebar-splitter,
          #sidebar-launcher-splitter {
            background-color: transparent !important;
            background-image: none !important;
          }

          /* In the revamped sidebar the panel is hosted by a small chrome
           * document of its own, whose surfaces are not reachable from the
           * window's stylesheet. */
          @-moz-document url-prefix("chrome://browser/content/webext-panels.xhtml") {
            :root,
            #webext-panels-stack,
            #webext-panels-browser {
              background-color: transparent !important;
            }
          }

          /* The bars take the theme's own toolbar colour at the opacity the
           * rest of the desktop uses — the terminal blurs at 0.80, the shell's
           * bars at 0.72 — so the glass follows a theme change instead of
           * repeating a palette here. */
          #nav-bar,
          #PersonalToolbar,
          #sidebar-box,
          #sidebar-container {
            background-color: color-mix(in srgb, var(--toolbar-background-color, #313244) 72%, transparent) !important;
          }

          /* The URL field keeps a lighter tint of its own, so it still reads as
           * a field over the brightest wallpaper and darkens while focused. */
          .urlbar-background {
            background-color: color-mix(in srgb, var(--toolbar-field-background-color, #45475a) 55%, transparent) !important;
          }
          #urlbar[focused] .urlbar-background {
            background-color: color-mix(in srgb, var(--toolbar-field-background-color, #45475a) 80%, transparent) !important;
          }
        '';
        userContent = ''
          /* Sidebery paints the sidebar from its own stylesheet, in its own
           * document, where the chrome stylesheet of the profile cannot reach;
           * a user content sheet does load there. Its frame colour is what
           * covers the sidebar, and Sidebery re-declares that colour on its
           * own root, so these have to be declared there too — an inherited
           * value would lose to that rule. Clearing it leaves the tint to the
           * chrome behind the panel, which keeps the sidebar on the same
           * material as the toolbar no matter which panel is open.
           *
           * The surfaces Sidebery floats above the sidebar — menus, tab
           * previews, the drag image, the selection badge — read the popup
           * colour instead, and those are where the wallpaper must not show
           * through, so they keep a near-opaque backing of the palette's
           * darkest tone. The extension cannot see the browser theme, so this
           * is the one place a colour is repeated from it.
           */
          @-moz-document regexp("moz-extension://[^/]+/sidebar/sidebar[.]html([?#].*)?") {
            html:has(#root_container),
            #root,
            #root_container {
              --s-frame-bg: transparent !important;
              --frame-bg: transparent !important;
            }

            html:has(#root_container),
            body:has(#root_container),
            #root_container,
            #root {
              background-color: transparent !important;
            }

            #root {
              --popup-bg: rgb(24 24 37 / 0.92) !important;
            }

            /* The panel row and the tab rows paint themselves with Sidebery's
             * own toolbar colour, which is opaque, so the blur stops at them
             * even though everything around them is glass. Clearing those
             * surfaces puts the rows on the same material; the active tab
             * keeps a light overlay of its own text colour so the selection
             * still reads without becoming a plate again. */
            #root .NavigationBar,
            #root .SubPanel .header,
            #root .Tab .body {
              background-color: transparent !important;
            }

            #root .Tab[data-active="true"] .body,
            #root .Tab[data-selected="true"] .body {
              background-color: color-mix(in srgb, currentColor 14%, transparent) !important;
            }

            #root .CtxMenu .box,
            #root .CtxMenu .sub-menu {
              background-color: var(--popup-bg) !important;
            }
          }
        '';
      };
    };
  };
}
