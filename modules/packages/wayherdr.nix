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
          rev = "5c6f81e7c0f8b7693582d15a910161dac54881ab";
          hash = "sha256-C/e+V1zr3KuCQjvysqwgz7YHUgFiQryAn8GAfSSXcFw=";
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
