{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
    in
    {
      packages.wayherdr = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "wayherdr";
        version = "0.1.0";

        src = pkgs.fetchFromGitHub {
          owner = "AsterisMono";
          repo = "waybar-toys";
          rev = "b6fb26af921082a53072bbbccc8757b3ae49d76c";
          hash = "sha256-A+0dKXlfj6CVW7OkfOQAh3IqN9bTp+lQKCKwwYxnB0Y=";
        };

        cargoHash = "sha256-SPgq2kWY7K+knQRID3wZOzffZU0VonY1ApBPga5Gd9E=";
        buildAndTestSubdir = "wayherdr";

        meta = {
          description = "Waybar plugin that shows the statuses of agents in a running herdr server";
          homepage = "https://github.com/AsterisMono/waybar-toys/tree/main/wayherdr";
          license = pkgs.lib.licenses.mit;
          mainProgram = "wayherdr";
          platforms = pkgs.lib.platforms.linux;
        };
      });
    };
}
