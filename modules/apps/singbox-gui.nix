{ inputs, ... }: {
  flake-file.inputs.sfd-nix.url = "git+https://forge.asnk.io/sugar/sfd-nix";
  flake.modules.nixos.singbox-gui = { config, lib, ... }: {
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
      sops.secrets.sing_box_config = {
        format = "json";
        sopsFile = config.constants.resources.getSecretPath "sing-box.json";
        key = "";
        mode = "0440";
        group = "wheel";
        restartUnits = [ "sing-box-daemon.service" ];
      };
      systemd.services.sing-box-daemon.after = [ "sops-nix.service" ];
      programs.sing-box-for-desktop = {
        enable = true;
        settings = {
          startAtLogin = true;
          appearance = "dark";
          core.disableDeprecatedWarnings = true;
        };
        profiles = [
          {
            name = "Default";
            configurationPath = config.sops.secrets.sing_box_config.path;
          }
        ];
      };
    };
  };
}
