{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
    in
    {
      packages.waycat = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "waycat";
        version = "0.1.0";

        src = pkgs.fetchFromGitHub {
          owner = "AsterisMono";
          repo = "waycat";
          rev = "b3ad19138cd36e01b3f631b420260a7634ce33a2";
          hash = "sha256-THQh5jSDYwLPjKs4j4SYLanDWhAApWtLEaPXcOOVfxk=";
        };

        cargoHash = "sha256-OYvNgmfNfjeMTGzADWTj4EXIWOj5snbnHrmHwkBL7vQ=";

        postInstall = ''
          install -Dm644 res/waycat.ttf $out/share/fonts/TTF/waycat.ttf
        '';

        meta = {
          description = "Lightweight animated CPU-load cat for Waybar and Polybar";
          homepage = "https://github.com/AsterisMono/waycat";
          license = pkgs.lib.licenses.mit;
          mainProgram = "waycat";
          platforms = pkgs.lib.platforms.linux;
        };
      });
    };
}
