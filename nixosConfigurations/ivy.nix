{
  config,
  nixosModules,
  pkgs,
  secretsPath,
  ...
}:
let
  thisTsAddress = "100.74.184.53";
in
{
  imports = with nixosModules; [
    roles.server
    services.tailscale
    services.dn42
    (services.prometheus-blackbox thisTsAddress)
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
        tunnelLocalAddr = "fdec:a476:db6e:ffff::2323:0/127";
        tunnelPeerAddr = "fdec:a476:db6e:ffff::2323:1/127";
      };
      "AS4242420994" = {
        endpoint = "***REMOVED***";
        pubkey = "***REMOVED***";
        tunnelLocalAddr = "fdd2:4372:796f:ffff::833:1/127";
        tunnelPeerAddr = "fdd2:4372:796f:ffff::833:0/127";
      };
      "AS4242420803" = {
        endpoint = "***REMOVED***";
        pubkey = "***REMOVED***";
        tunnelLocalAddr = "fe80::833/64";
        tunnelPeerAddr = "fe80::803/64";
        extendedNextHop = true;
      };
    };
  };

  services.prometheus.exporters =
    let
      networkSettings = {
        listenAddress = thisTsAddress; # Tailscale
        openFirewall = true;
      };
    in
    {
      node = {
        enable = true;
        port = 9100;
        enabledCollectors = [
          "systemd"
          "netdev.address-info"
        ];
        disabledCollectors = [ "textfile" ];
      }
      // networkSettings;
      bird = {
        enable = true;
        port = 9324;
      }
      // networkSettings;
      wireguard = {
        enable = true;
        port = 9586;
        latestHandshakeDelay = true;
      }
      // networkSettings;
    };
}
