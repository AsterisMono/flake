{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
    in
    {
      packages.herdr-reviewr = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "herdr-reviewr";
        version = "0.36.0";

        src = pkgs.fetchFromGitHub {
          owner = "persiyanov";
          repo = "herdr-reviewr";
          rev = "d172ea257ea39bc0eddc9608df1c405744c19e56";
          hash = "sha256-S9IsjUr2RZqVXX38QchcsknpXL7yOSlAkwGG4lJ3ol4=";
        };

        cargoHash = "sha256-Ef+jPqPCBt1f4XzT+2rTF2oGKd6jWJ6VHf5GRhuBR0g=";

        nativeBuildInputs = with pkgs; [
          makeWrapper
          pkg-config
        ];

        buildInputs = with pkgs; [
          libgit2
          oniguruma
          zlib
        ];

        env = {
          LIBGIT2_NO_VENDOR = true;
          RUSTONIG_SYSTEM_LIBONIG = true;
        };

        # Upstream's integration tests exercise Herdr pane behavior and are too
        # heavyweight for this local plugin package.
        doCheck = false;

        postPatch = ''
          substituteInPlace herdr/pane.sh \
            --replace-fail 'export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:''${PATH:-}"' \
            'export PATH="${
              pkgs.lib.makeBinPath (
                with pkgs;
                [
                  git
                  jq
                ]
              )
            }:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:''${PATH:-}"'
        '';

        postInstall = ''
          wrapProgram $out/bin/herdr-reviewr \
            --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs; [ git ])}

          cp -R herdr herdr-plugin.toml README.md LICENSE $out/
        '';

        meta = {
          description = "Code-review pane for Herdr";
          homepage = "https://github.com/persiyanov/herdr-reviewr";
          changelog = "https://github.com/persiyanov/herdr-reviewr/blob/${finalAttrs.src.rev}/CHANGELOG.md";
          license = pkgs.lib.licenses.mit;
          mainProgram = "herdr-reviewr";
          platforms = pkgs.lib.platforms.linux ++ pkgs.lib.platforms.darwin;
        };
      });
    };
}
