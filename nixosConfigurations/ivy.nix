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
    services.dn42
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
    wireguard-tools
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

  noa.dn42 = {
    enable = true;
    waitForInterface = "enu1";
    asInfo = {
      asn = "AS4242420833";
      routerIp = "fdec:a476:db6e::fade:cafe";
      routerId = "224.6.107.225";
      subnet = "fdec:a476:db6e::/48";
    };
    peers = {
      "AS4242422323" = {
        endpoint = "***REMOVED***";
        pubkey = "***REMOVED***";
        tunnelLocalAddr = "ee80:759::0833/64";
        tunnelPeerAddr = "ee80:759::2323/64";
      };
    };
  };
}
