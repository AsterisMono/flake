{
  lib,
  stdenvNoCC,
  fetchurl,
  writeShellApplication,
  cacert,
  curl,
  common-updater-scripts,
  pup,
  _7zz,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "orbstack";
  version = "1.11.3";

  src = fetchurl {
    url = "https://cdn-updates.orbstack.dev/arm64/OrbStack_v1.11.3_19358_arm64.dmg";
    hash = "sha256-/zujkmctMdJUm3d7Rjjeic8QrvWSlEAUhjFgouBXeNw=";
  };

  unpackCmd = "7zz x -snld $curSrc";

  nativeBuildInputs = [ _7zz ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R OrbStack.app "$out/Applications"

    mkdir -p "$out/bin"
    ln -s "$out/Applications/OrbStack.app/Contents/MacOS/Orbstack" "$out/bin/orbstack"

    for bindir in bin xbin; do
      for binary in "$out/Applications/OrbStack.app/Contents/MacOS/$bindir"/*; do
        if [[ -f "$binary" ]]; then
          ln -s "$binary" "$out/bin/$(basename "$binary")"
        fi
      done
    done

    runHook postInstall
  '';

  # passthru.updateScript = lib.getExe (writeShellApplication {
  #   name = "shottr-update-script";
  #   runtimeInputs = [
  #     cacert
  #     common-updater-scripts
  #     curl
  #     pup
  #   ];
  #   text = ''
  #     version="$(curl -s https://shottr.cc/newversion.html \
  #       | pup 'a[href*="Shottr-"] attr{href}' \
  #       | sed -E 's|/dl/Shottr-||' \
  #       | sed -E 's|\.dmg||')"
  #     update-source-version shottr "$version"
  #   '';
  # });

  meta = {
    changelog = "https://docs.orbstack.dev/release-notes";
    description = "Fast, light, and easy way to run Docker containers and Linux machines";
    homepage = "https://orbstack.dev/";
    license = lib.licenses.unfree;
    mainProgram = "orbstack";
    maintainers = with lib.maintainers; [ asterismono ];
    platforms = lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
