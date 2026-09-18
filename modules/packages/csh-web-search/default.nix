_: {
  perSystem =
    { pkgsUnstable, ... }:
    let
      pkgs = pkgsUnstable;
    in
    {
      packages.csh-web-search = pkgs.stdenvNoCC.mkDerivation {
        pname = "csh-web-search";
        version = "1.0.0";

        nativeBuildInputs = [ pkgs.makeWrapper ];

        dontUnpack = true;
        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall

          install -Dm444 ${./csh-web-search.py} \
            $out/share/csh-web-search/csh-web-search.py

          makeWrapper ${pkgs.python3}/bin/python3 $out/bin/csh-web-search \
            --add-flags "$out/share/csh-web-search/csh-web-search.py"

          runHook postInstall
        '';

        meta = {
          description = "MCP stdio server exposing a Codex web.run-style search tool backed by DeepSeek native web search";
          longDescription = ''
            Provides a single ``run`` tool whose `search_query` command mirrors
            the search subset of Codex's standalone web-search tool. Each query
            runs one Anthropic-compatible Messages request against DeepSeek with
            the native `web_search_20250305` server tool and returns a
            synthesized answer plus a reference-ID source list to the model.
          '';
          license = pkgs.lib.licenses.mit;
          platforms = pkgs.lib.platforms.unix;
          mainProgram = "csh-web-search";
        };
      };
    };
}
