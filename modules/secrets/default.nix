{
  flake-file.inputs.sops-nix.url = "github:Mic92/sops-nix";

  flake.modules.generic.secrets = { lib, ... }: {
    options.secrets = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
    };

    config.secrets = {
      sing-box-config = {
        format = "json";
        sopsFile = ./sing-box.json;
        path = "/etc/sing-box/config.json";
        key = "";
        restartUnits = [ "sing-box.service" ];
      };
    };
  };

  flake.modules.nixos.secrets = {
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  flake.modules.home.secrets = { config, ... }: {
    sops.age.keyFile = "/home/${config.constants.nvirellia.username}/.config/sops/age/keys.txt";
  };
}
