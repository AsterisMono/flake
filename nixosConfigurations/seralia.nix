{
  config,
  nixosModules,
  secretsPath,
  ...
}:
{
  imports = with nixosModules; [
    diskLayouts.btrfs
    roles.server
    services.tailscale
    services.docker
  ];

  disko.devices.disk.main.device = "/dev/vda";

  noa.docker.enableWatchTower = true;

  sops.secrets.pocket-id = {
    sopsFile = "${secretsPath}/pocketId.env";
    format = "dotenv";
    key = "";
  };

  virtualisation.oci-containers.containers.pocket-id = {
    image = "ghcr.io/pocket-id/pocket-id:v1";
    volumes = [ "/var/lib/pocketid:/app/data" ];
    ports = [ "127.0.0.1:1411:1411" ];
    environmentFiles = [ config.sops.secrets.pocket-id.path ];
  };

  services.caddy = {
    enable = true;
    globalConfig = ''
      email cmiki@amono.me
    '';
    virtualHosts = {
      "citadel.requiem.garden".extraConfig = ''
        reverse_proxy 127.0.0.1:1411
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
