{
  config,
  nixosModules,
  pkgs,
  secretsPath,
  ...
}:
{
  imports = with nixosModules; [
    roles.server
    services.tailscale
  ];

  noa.nix.enableMirrorSubstituter = true;

  environment.systemPackages = with pkgs; [
    bpftools
    ethtool
    f2fs-tools
    iperf
    lm_sensors
    mtr
    traceroute
    tcpdump
    conntrack-tools
  ];

  sops.secrets.cloudflare-ddns-apikey = {
    format = "yaml";
    sopsFile = "${secretsPath}/dn42.yaml";
    key = "cloudflare_ddns_apikey";
  };

  services.ddclient = {
    enable = true;
    usev4 = "disabled";
    usev6 = "ifv6, if=enu1";
    protocol = "cloudflare";
    zone = "requiem.garden";
    username = "token";
    passwordFile = config.sops.secrets.cloudflare-ddns-apikey.path;
    domains = [ "ivy.requiem.garden" ];
  };
}
