{ inputs, ... }:
{
  flake-file.inputs.noctalia = {
    url = "github:noctalia-dev/noctalia";
  };

  flake.modules.nixos.noctalia =
    { ... }:
    {
      imports = [ inputs.noctalia.nixosModules.default ];

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
}
