{ lib, ... }:
{
  flake.modules.nixos.forgejo-runner =
    {
      config,
      pkgs,
      ...
    }:
    {
      sops.secrets.forgejo_runner_token = {
        sopsFile = config.constants.resources.getSecretPath "forgejo-runner.yaml";
        format = "yaml";
        key = "token";
        restartUnits = [ "gitea-runner-my\\x2dforgejo\\x2dinstance.service" ];
      };

      sops.templates."forgejo-runner.env" = {
        content = ''
          TOKEN=${config.sops.placeholder.forgejo_runner_token}
        '';
        mode = "0400";
      };

      services.gitea-actions-runner = {
        package = pkgs.forgejo-runner;
        instances.my-forgejo-instance = {
          enable = true;
          name = "my-forgejo-runner-01";
          tokenFile = config.sops.templates."forgejo-runner.env".path;
          url = "https://forge.asnk.io/";
          labels = [
            "node-22:docker://node:22-bookworm"
            "nixos-latest:docker://nixos/nix"
          ];
          settings = { };
        };
      };

      systemd.services."gitea-runner-my\\x2dforgejo\\x2dinstance".after = lib.mkAfter [
        "sops-install-secrets.service"
      ];
    };
}
