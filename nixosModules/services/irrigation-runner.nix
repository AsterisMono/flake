{ config, secretsPath, ... }:
{
  users.groups.github = { };

  users.extraUsers.github = {
    isSystemUser = true;
    group = "github";
  };

  sops.secrets.ci_runner_token = {
    format = "yaml";
    sopsFile = "${secretsPath}/github.yaml";
    restartUnits = [
      "github-runner-irrigation.service"
    ];
  };

  services.github-runners = {
    irrigation = {
      enable = true;
      name = "irrigation";
      tokenFile = config.sops.secrets.ci_runner_token.path;
      user = "github";
      url = "https://github.com/AsterisMono/flake";
      serviceOverrides = {
        # Allow read-only access to .ssh
        ProtectHome = "read-only";
      };
    };
  };
}
