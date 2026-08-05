{ inputs, ... }: {
  flake-file.inputs = {
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    {
      checks = {
        pre-commit-check = inputs.git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt.enable = true;
            statix.enable = true;
            convco.enable = true;
          };
        };
      };

      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          nixd
          nixfmt
          just
          sops
          nh
        ];
        inherit (config.checks.pre-commit-check) shellHook;
        buildInputs = config.checks.pre-commit-check.enabledPackages;
      };
    };
}
