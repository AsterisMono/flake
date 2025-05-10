{ pkgs, nixosModules, ... }:
let
  yaml = pkgs.formats.yaml { };
in
{
  imports = with nixosModules; [
    server.base
    diskLayouts.btrfs
    tailscale
    users.cmiki
  ];

  disko.devices.disk.main.device = "/dev/sda";

  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
  ];

  services.k3s.enable = true;
  services.k3s.role = "server";

  environment.etc."rancher/k3s/registries.yaml".source = yaml.generate "registries.yaml" {
    mirrors = {
      "docker.io".endpoint = [ "https://docker.1ms.run" ];
      "ghcr.io".endpoint = [ "https://ghcr.m.daocloud.io" ];
      "gcr.io".endpoint = [ "https://gcr.m.daocloud.io" ];
      "registry.k8s.io".endpoint = [ "https://k8s.m.daocloud.io" ];
      "quay.io".endpoint = [ "https://quay.m.daocloud.io" ];
    };
  };
}
