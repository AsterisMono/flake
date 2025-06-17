{
  config,
  nixosModules,
  homeModules,
  secretsPath,
  ...
}:
{
  imports = with nixosModules; [
    roles.server
    diskLayouts.btrfs
    services.proxy
    services.tailscale
    services.ssh
    users.cmiki
  ];

  disko.devices.disk.main.device = "/dev/sda";

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
      user = "cmiki";
      url = "https://github.com/AsterisMono/flake";
      serviceOverrides = {
        # Allow read-only access to .ssh
        ProtectHome = "read-only";
      };
    };
  };

  noa = {
    nix.enableMirrorSubstituter = true;
    homeManager.enable = true;
    homeManager.modules = with homeModules; [
      apps.shell-utils
      apps.development
    ];
    proxy.tunMode = true;
  };
}
