_: {
  perSystem =
    { pkgsUnstable, ... }:
    let
      pkgs = pkgsUnstable;
    in
    {
      packages.herdr-projects = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "herdr-projects";
        version = "0.2.5";

        src = pkgs.fetchFromGitHub {
          owner = "eliasstravik";
          repo = "herdr-projects";
          rev = "05060c285303fd46cef778cd95750311e715a580";
          hash = "sha256-JqEACceyqOhY7BP953xkc+l5lZ+VFmcZrWtm80DcgIA=";
        };

        cargoHash = "sha256-0a6c8DFxCYJcVpeou5oKHxhDAkBvddWPx+eNBf2ZqF4=";

        # The manifest addresses the plugin's own binary the way
        # `herdr plugin install` builds it — `cargo build --release` inside the
        # plugin checkout, so `target/release/herdr-projects` relative to the
        # plugin root. Keep that layout; `$out/bin` alone would not resolve.
        # Cargo builds into a target-specific directory here, so take the
        # installed binary rather than a path under `target/`.
        postInstall = ''
          install -Dm755 $out/bin/herdr-projects $out/target/release/herdr-projects
          cp -R herdr-plugin.toml README.md LICENSE $out/
        '';

        # Upstream's tests reach outside the build: they run rsync and git
        # against real repositories, read local time zone data, and time a
        # process group kill. 139 of them pass here, 7 cannot.
        doCheck = false;

        # build.rs stamps the current time into the version string, which no
        # two builds would agree on. Keep the revision instead.
        postPatch = ''
          substituteInPlace build.rs \
            --replace-fail 'HP_BUILD_ID={hash}.{secs}' 'HP_BUILD_ID=${finalAttrs.src.rev}'
        '';

        meta = {
          description = "Coordinator conversations, parallel worker threads, and shared memory for Herdr";
          homepage = "https://github.com/eliasstravik/herdr-projects";
          changelog = "https://github.com/eliasstravik/herdr-projects/blob/${finalAttrs.src.rev}/CHANGELOG.md";
          license = pkgs.lib.licenses.mit;
          mainProgram = "herdr-projects";
          platforms = pkgs.lib.platforms.linux ++ pkgs.lib.platforms.darwin;
        };
      });
    };
}
