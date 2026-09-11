{
  inputs,
  ...
}:
{
  perSystem =
    { system, ... }:
    let
      pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
      # RS256 signing goes through `cryptography`; `openssl` is the documented
      # fallback backend and is generally useful on the agent host.
      python = pkgs.python3.withPackages (ps: [ ps.cryptography ]);
      # The 1Password CLI is deliberately NOT bundled: it is unfree, so
      # depending on it would make this package unbuildable without
      # `allowUnfree`. `op` is expected on the ambient PATH (the consuming
      # module installs pkgs._1password-cli) and makeWrapper does not clear
      # PATH, so it still resolves at runtime.
      runtimePath = pkgs.lib.makeBinPath [ pkgs.openssl ];
    in
    {
      packages.github-app-token = pkgs.stdenvNoCC.mkDerivation {
        pname = "github-app-token";
        version = "1.0.0";

        nativeBuildInputs = [ pkgs.makeWrapper ];

        dontUnpack = true;
        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall

          install -Dm444 ${./github-app-token.py} \
            $out/share/github-app-token/github-app-token.py
          install -Dm444 ${./github-app-env.sh} \
            $out/share/github-app-token/github-app-env.sh

          makeWrapper ${python}/bin/python3 $out/bin/github-app-token \
            --add-flags "$out/share/github-app-token/github-app-token.py" \
            --prefix PATH : ${runtimePath}

          runHook postInstall
        '';

        meta = {
          description = "Mint short-lived GitHub App installation tokens";
          longDescription = ''
            Mints one-hour GitHub App installation tokens from an app private
            key held in a password manager, so an agent can act under its own
            identity instead of a human's account. Caches the token with a
            refresh skew, normalizes PEM input, and can discover the app's
            installation id.
          '';
          license = pkgs.lib.licenses.mit;
          platforms = pkgs.lib.platforms.unix;
          mainProgram = "github-app-token";
        };
      };
    };
}
