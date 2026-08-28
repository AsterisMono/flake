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
          repo = "wayherdr";
          rev = "b8a1df82d0514031bd78ab8852746ab67d599a10";
          hash = "sha256-pID/mqpgmdsaD32RnuSHgnYM47zt7/+3c9Tl7pQiw58=";
        };

        cargoHash = "sha256-DwQsX1mas0/b0vf3C//CR866BX/PMSkSg8Vui9c0VBk=";

        meta = {
          description = "Waybar plugin that shows the statuses of agents in a running herdr server";
          homepage = "https://github.com/AsterisMono/wayherdr";
          license = pkgs.lib.licenses.mit;
          mainProgram = "wayherdr";
          platforms = pkgs.lib.platforms.linux;
        };
      });
    };
}
