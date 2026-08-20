{ inputs, ... }: {
  flake-file.inputs.sfd-nix.url = "git+https://forge.asnk.io/sugar/sfd-nix";
  flake.modules.nixos.singbox-gui = { lib, ... }: {
    imports = [ inputs.sfd-nix.nixosModules.default ];

    options.security.polkit.enablePkexecWrapper = lib.mkEnableOption "dummy";

    config = {
      nix.settings = {
        substituters = [
          "https://sfd-nix.cachix.org"
        ];
        trusted-public-keys = [
          "sfd-nix.cachix.org-1:SX5EpvFvgFZXgG94/0fX1L+lUWQ90dPq0Ieor7/rDig="
        ];
      };
      programs.sing-box-for-desktop.enable = true;
    };
  };
}
