{ buildFirefoxXpiAddon, fetchurl, lib, stdenv }:
{
  "i-still-dont-care-about-cookies" = buildFirefoxXpiAddon {
    pname = "i-still-dont-care-about-cookies";
    version = "1.0.7";
    addonId = "idcac-pub@guus.ninja";
    url = "https://addons.mozilla.org/firefox/downloads/file/4019706/istilldontcareaboutcookies-1.0.7.xpi";
    sha256 = "f7e3e9813018443b52823493f05c0e7ac76b1e69c7e1a746768bc7878d605895";
    meta = with lib;
      {
        homepage = "https://github.com/OhMyGuus/I-Dont-Care-About-Cookies";
        description = ''Community version of the popular extension "I' don't care about cookies"'';
        license = licenses.gpl3;
        platforms = platforms.all;
      };
  };

  "vimium-ff" = buildFirefoxXpiAddon {
    pname = "vimium-ff";
    version = "1.67.2";
    addonId = "{d7742d87-e61d-4b78-b8a1-b469842139fa}";
    url = "https://addons.mozilla.org/firefox/downloads/file/4017172/vimium_ff-1.67.2.xpi";
    sha256 = "7fc94359b7584f7f121cb709101940d3f0dc8e80a41dd83dadc3c4446675face";
    meta = with lib;
      {
        homepage = "https://github.com/philc/vimium";
        description = "The Hacker's Browser. Vimium provides keyboard shortcuts for navigation and control in the spirit of Vim.\n\nThis is a port of the popular Chrome extension to Firefox.\n\nMost stuff works, but the port to Firefox remains a work in progress.";
        license = licenses.mit;
        platforms = platforms.all;
      };
  };
}
