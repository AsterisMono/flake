{
  inputs,
  ...
}:
let
  # Upstream publishes per Rust target triple. There is no x86_64 musl build,
  # so the glibc archive is the only option and autoPatchelfHook is required.
  targetFor =
    system:
    {
      x86_64-linux = "x86_64-unknown-linux-gnu";
      aarch64-linux = "aarch64-unknown-linux-gnu";
    }
    .${system} or null;
in
{
  perSystem =
    { system, ... }:
    let
      pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
      target = targetFor system;
    in
    {
      packages.tirith = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "tirith";
        version = "0.4.1";

        src = pkgs.fetchurl {
          url = "https://github.com/sheeki03/tirith/releases/download/v${finalAttrs.version}/tirith-${target}.tar.gz";
          hash = "sha256-pQNfT96Bs0zQz2nSQVGxUEVSrjUrTrfIjEms1WKJNi4=";
        };

        # The shipped binaries are generic glibc ELF executables, which NixOS
        # cannot exec from a non-store path. Repatch them into the store.
        nativeBuildInputs = [ pkgs.autoPatchelfHook ];
        buildInputs = [ pkgs.glibc ];

        dontConfigure = true;
        dontBuild = true;

        # The archive has several top-level entries (binaries, man/, completions/),
        # so there is no single directory for the unpacker to pick.
        sourceRoot = ".";

        installPhase = ''
          runHook preInstall

          install -Dm755 tirith $out/bin/tirith
          install -Dm755 tirith-package-approval-authority \
            $out/bin/tirith-package-approval-authority

          install -Dm644 man/tirith.1 $out/share/man/man1/tirith.1
          install -Dm644 completions/tirith.bash \
            $out/share/bash-completion/completions/tirith
          install -Dm644 completions/tirith.fish \
            $out/share/fish/vendor_completions.d/tirith.fish
          install -Dm644 completions/_tirith $out/share/zsh/site-functions/_tirith

          runHook postInstall
        '';

        meta = {
          description = "Pre-exec command scanner for content-level threats";
          longDescription = ''
            Scans shell commands and tool input for homograph URLs,
            pipe-to-interpreter patterns, terminal escape injection and
            similar content-level threats. Used by Hermes as a fail-open
            pre-execution guard.
          '';
          homepage = "https://tirith.sh";
          # Upstream is AGPL-3.0; this derivation redistributes the published
          # release binaries, which is why the provenance is native code.
          license = pkgs.lib.licenses.agpl3Plus;
          sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
          platforms = [
            "x86_64-linux"
            "aarch64-linux"
          ];
          mainProgram = "tirith";
        };
      });
    };
}
