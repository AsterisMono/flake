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

    # Fix "this app is damaged and can't be opened"
    #
    # When extracting an APFS .dmg with 7zz (7-Zip), it may incorrectly turn
    # macOS extended attributes (like quarantine or macl) into real files:
    #   Info.plist:com.apple.quarantine
    #   Info.plist:com.apple.macl
    #
    # These bogus files corrupt the .app bundle and prevent it from launching.
    # Delete them to restore proper behavior.
    find OrbStack.app -name '*:com.apple.*' -delete

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

  passthru.updateScript = lib.getExe (writeShellApplication {
    name = "orbstack-update-script";
    runtimeInputs = [
      cacert
      common-updater-scripts
      curl
      pup
    ];
    text = ''
      source_url="$(curl -L -I https://orbstack.dev/download/stable/latest/arm64 | grep -i "location:" | awk '{print $2}')"
      version="$(echo "$source_url" | sed -E 's|.*/OrbStack_v||' | sed -E 's|_[0-9]+_arm64\.dmg||')"
      update-source-version orbstack "$version" "$source_url"
    '';
  });

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
