{
  stdenvNoCC,
  fetchzip,
  lib,
}:
stdenvNoCC.mkDerivation {
  pname = "vicinae-gnome-extension";
  version = "1.5.1";
  src = fetchzip {
    url = "https://github.com/dagimg-dot/vicinae-gnome-extension/releases/download/v1.5.1/vicinae@dagimg-dot.shell-extension-v1.5.1.zip";
    hash = "sha256-/JEntSdmShxzayY0Cd1PjQCWeAV/AqbpqMtFUbDI0e8=";
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
