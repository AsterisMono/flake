{
  stdenvNoCC,
  fetchzip,
  lib,
}:
stdenvNoCC.mkDerivation {
  pname = "vicinae-gnome-extension";
  version = "1.5.0";
  src = fetchzip {
    url = "https://github.com/AsterisMono/vicinae-gnome-extension/releases/download/v1.5.0-fix-schemas/vicinae@dagimg-dot.shell-extension-v1.5.0.zip";
    hash = "sha256-VCnL+ItmXJR6ihdb7marTSEJyGOjzB0G6OpLzdAfPPM=";
    stripRoot = false;
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions/vicinae@dagimg-dot
    cp -r ./* $out/share/gnome-shell/extensions/vicinae@dagimg-dot
    runHook postInstall
  '';

  meta.platforms = lib.platforms.all;
}
