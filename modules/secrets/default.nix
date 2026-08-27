{ inputs, ... }: {
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.secrets = {
    imports = [
      inputs.sops-nix.nixosModules.sops
    ];

    sops = {
      useSystemdActivation = true;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
  };

  flake.modules.homeManager.secrets = { config, ... }: {
    imports = [
      inputs.sops-nix.homeManagerModules.sops
    ];

    sops.age.keyFile = "/home/${config.constants.nvirellia.username}/.config/sops/age/keys.txt";
  };
}
