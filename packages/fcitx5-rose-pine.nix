{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "fcitx5-rose-pine";
  version = "unstable-2025-11-05";

  src = fetchFromGitHub {
    owner = "rose-pine";
    repo = "fcitx5";
    rev = "01c291bc4fa5095c7a7c2ab177a9efc2042c5026";
    hash = "sha256-pNFDzsURMsNUJRz1jjyOb9uLjCtMbNuo3ARvv0rsvLg=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fcitx5/themes
    cp -r rose-pine/ rose-pine-moon/ rose-pine-dawn/ $out/share/fcitx5/themes
    runHook postInstall
  '';

  meta = {
    description = "Soho vibes for fcitx5";
    homepage = "https://github.com/rose-pine/fcitx5";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ asterismono ];
    platforms = lib.platforms.all;
  };
}
