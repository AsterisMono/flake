{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
    in
    {
      packages.waycodex = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "waycodex";
        version = "0.1.0";

        src = pkgs.fetchFromGitHub {
          owner = "AsterisMono";
          repo = "waybar-toys";
          rev = "31417069e993b39f407a5ec6b8ae48f57cadb32e";
          hash = "sha256-i7fENmi9mIQnAKBociHoTvwDj8P/QRNXBl+xEphih5E=";
        };

        cargoHash = "sha256-+W5nJpKWlP+ce0f8VrGLlezx4fTY9fxiSOiL+YO6pEs=";
        buildAndTestSubdir = "waycodex";

        meta = {
          description = "Waybar plugin showing OpenAI Codex usage limits and banked resets";
          homepage = "https://github.com/AsterisMono/waybar-toys/tree/main/waycodex";
          license = pkgs.lib.licenses.mit;
          mainProgram = "waycodex";
          platforms = pkgs.lib.platforms.linux;
        };
      });
    };
}
