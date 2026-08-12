{
  flake-file.inputs.sops-nix.url = "github:Mic92/sops-nix";

  flake.modules.nixos.secrets = {
    sops = {
      useSystemdActivation = true;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
  };

  flake.modules.home.secrets = { config, ... }: {
    sops.age.keyFile = "/home/${config.constants.nvirellia.username}/.config/sops/age/keys.txt";
  };
}
