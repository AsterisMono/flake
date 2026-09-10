{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
    in
    {
      packages.honcho-ai = pkgs.python3Packages.buildPythonPackage rec {
        pname = "honcho-ai";
        version = "2.2.0";
        format = "wheel";

        src = pkgs.fetchurl {
          url = "https://files.pythonhosted.org/packages/d0/c6/66af5f7ba3d75796f4523eac1e069fbdc759c3f0b8adab9fb7ae04e15784/honcho_ai-2.2.0-py3-none-any.whl";
          hash = "sha256-MvCYpMi8/kKI8JlN2rC8UqaNyHBp0PLOLIdY7ioXYfI=";
        };

        # httpx and pydantic are already provided by the Hermes runtime env;
        # declaring them here would risk shadowing Hermes' pinned versions.
        dependencies = [ ];
        dontCheckRuntimeDeps = true;

        doCheck = false;

        meta = {
          description = "Official DX Optimized Python SDK for Honcho";
          homepage = "https://github.com/plastic-labs/honcho";
          license = pkgs.lib.licenses.agpl3Plus;
          platforms = pkgs.lib.platforms.unix;
        };
      };
    };
}
