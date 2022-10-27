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
}
