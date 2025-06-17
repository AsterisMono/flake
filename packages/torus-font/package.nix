{ stdenvNoCC, unzip }:
stdenvNoCC.mkDerivation {
  pname = "torus-font";
  version = "1.0";

  src = ./Torus.zip;

  unpackPhase = ''
    runHook preUnpack
    ${unzip}/bin/unzip $src

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 *.otf -t $out/share/fonts/truetype

    runHook postInstall
  '';
}
