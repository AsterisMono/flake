{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    arion
    docker-client
  ];

  virtualisation = {
    docker.enable = false;
    podman = {
      enable = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
