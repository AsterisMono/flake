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
        endpoint = "home.kagura.lolicon.cyou:20833";
        pubkey = "z3XndJnzBW9D+S6flQ+nlJH+WlrCcGtImdN4kUb/LGM=";
        tunnelLocalAddr = "ee80:759::0833/64";
        tunnelPeerAddr = "ee80:759::2323/64";
      };
      "AS4242420994" = {
        endpoint = "hgt0ae5n23e.sn.mynetname.net:20833";
        pubkey = "oJStkRIo8cO4IGj/+Tdi2FcK/eDg1NR4dF9ZNIqPyVg=";
        tunnelLocalAddr = "ee80:5::0833/64";
        tunnelPeerAddr = "ee80:5::0994/64";
      };
    };
  };
}
