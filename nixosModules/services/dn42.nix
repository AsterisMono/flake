{
  config,
  lib,
  secretsPath,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
  cfg = config.noa.dn42;
  peerOpts = _: {
    options = {
      endpoint = mkOption {
        example = "home.kagura.lolicon.cyou";
        type = types.str;
        description = ''
          The endpoint of the peer.
        '';
      };
      pubkey = mkOption {
        example = "z3XndJnzBW9D+S6flQ+nlJH+WlrCcGtImdN4kUb/LGM=";
        type = types.str;
        description = ''
          The pubkey of the peer.
        '';
      };
      tunnelLocalAddr = mkOption {
        example = "fe80::fade:cafe/64";
        default = "fe80::fade:cafe/64";
        type = types.str;
        description = ''
          The ip address on the local side of the tunnel.
        '';
      };
      tunnelPeerAddr = mkOption {
        example = "fe80::759:2323/64";
        type = types.str;
        description = ''
          The ip address on the peer side of the tunnel, provided by the peer.
        '';
      };
    };
  };
  mkDn42AsnSuffix = asn: lib.removePrefix "AS424242" asn;
  mkDn42WgIfname = asn: "dn42wg${lib.removePrefix "AS424242" asn}";
  mkDn42WgPort = asn: lib.toInt "2${mkDn42AsnSuffix asn}";
  generateSopsAccess = asn: values: {
    "peers/${asn}/my_private_key" = {
      format = "yaml";
      owner = "systemd-network";
      sopsFile = "${secretsPath}/dn42.yaml";
      restartUnits = [ "systemd-networkd.service" ];
    };
  };
  generateNetworkdConfig =
    asn: values:
    let
      networkdEntry = "peer-${asn}";
      ifname = mkDn42WgIfname asn;
    in
    {
      netdevs."${lib.toLower networkdEntry}" = {
        netdevConfig = {
          Name = ifname;
          Kind = "wireguard";
        };
        wireguardConfig = {
          ListenPort = mkDn42WgPort asn;
          PrivateKeyFile = config.sops.secrets."peers/${asn}/my_private_key".path;
        };
        wireguardPeers = [
          {
            PublicKey = values.pubkey;
            Endpoint = values.endpoint;
            # TODO: is this too open?
            AllowedIPs = [
              "::/0"
              "0.0.0.0/0"
            ];
            RouteTable = "off";
          }
        ];
      };
      networks."${lib.toLower networkdEntry}" = {
        matchConfig = {
          Name = ifname;
        };
        networkConfig = {
          Description = "Wireguard tunnel to DN42 peer ${asn}";
          DHCP = "no";
          IPv6AcceptRA = false;
          KeepConfiguration = "yes";
          BindCarrier = cfg.waitForInterface;
        };
        linkConfig = {
          RequiredForOnline = "no";
        };
        address = [ values.tunnelLocalAddr ];
      };
    };
in
{
  options = {
    noa.dn42 = {
      enable = mkEnableOption "DN42 Service";
      waitForInterface = mkOption {
        description = "Wait for a specific interface to come online before starting tunnels";
        type = types.str;
        default = null;
        example = "enu1";
      };
      peers = mkOption {
        description = "DN42 Peers";
        default = { };
        example = {
          "AS4242422323" = {
            endpoint = "home.kagura.lolicon.cyou:20833";
            pubkey = "z3XndJnzBW9D+S6flQ+nlJH+WlrCcGtImdN4kUb/LGM=";
            tunnelLocalAddr = "fe80::fade:cafe/64";
            tunnelPeerAddr = "fe80:759::2323/64";
          };
        };
        type = with types; attrsOf (submodule peerOpts);
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.peers != { }) {
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.default.forwarding" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv4.conf.default.rp_filter" = 0;
      "net.ipv4.conf.all.rp_filter" = 0;
    };
    sops.secrets = lib.concatMapAttrs generateSopsAccess cfg.peers;
    systemd.network = lib.concatMapAttrs generateNetworkdConfig cfg.peers;
    networking.firewall =
      let
        asns = lib.attrNames cfg.peers;
      in
      {
        trustedInterfaces = map mkDn42WgIfname asns;
        allowedUDPPorts = map mkDn42WgPort asns;
      };
  };
}
