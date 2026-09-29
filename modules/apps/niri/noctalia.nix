{ inputs, ... }:
{
  flake-file.inputs.noctalia = {
    url = "github:noctalia-dev/noctalia";
  };

  # The community plugin felipeartur/ai-usagebar runs this CLI by name.
  flake-file.inputs.ai-usagebar = {
    url = "github:akitaonrails/ai-usagebar";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.noctalia =
    { pkgs, ... }:
    {
      imports = [ inputs.noctalia.nixosModules.default ];

      environment.systemPackages = [
        # Noctalia drives external monitor brightness through ddcutil.
        pkgs.ddcutil
        # The community ai-usagebar plugin's bar widget and panel.
        inputs.ai-usagebar.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      # Noctalia publishes prebuilt binaries on its own cache; following
      # nixpkgs would change the derivations and miss it.
      nix.settings = {
        extra-substituters = [ "https://noctalia.cachix.org" ];
        extra-trusted-public-keys = [
          "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        ];
      };

      programs.noctalia = {
        enable = true;
        systemd.enable = true;
      };
    };

  flake.modules.homeManager.noctalia =
    { ... }:
    {
      imports = [ inputs.noctalia.homeModules.default ];

      programs.noctalia = {
        enable = true;
        # The live settings, pinned as the declarative base layer; the shell's
        # state-dir settings still override it at runtime.
        settings = ./noctalia.toml;
      };
    };
}
