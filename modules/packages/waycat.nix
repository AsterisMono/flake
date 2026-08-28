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
          repo = "waybar-toys";
          rev = "b6fb26af921082a53072bbbccc8757b3ae49d76c";
          hash = "sha256-A+0dKXlfj6CVW7OkfOQAh3IqN9bTp+lQKCKwwYxnB0Y=";
        };

        cargoHash = "sha256-SPgq2kWY7K+knQRID3wZOzffZU0VonY1ApBPga5Gd9E=";
        buildAndTestSubdir = "waycat";

        postInstall = ''
          install -Dm644 waycat/res/waycat.ttf $out/share/fonts/TTF/waycat.ttf
        '';

        meta = {
          description = "Lightweight animated CPU-load cat for Waybar and Polybar";
          homepage = "https://github.com/AsterisMono/waybar-toys/tree/main/waycat";
          license = pkgs.lib.licenses.mit;
          mainProgram = "waycat";
          platforms = pkgs.lib.platforms.linux;
        };
      });
    };
}
