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
      asnSuffix = lib.removePrefix "AS424242" asn;
      networkdEntry = "peer-${asn}";
      ifname = "dn42wg${asnSuffix}";
    in
    {
      netdevs."${lib.toLower networkdEntry}" = {
        netdevConfig = {
          Name = ifname;
          Kind = "wireguard";
        };
        wireguardConfig = {
          ListenPort = lib.toInt "2${asnSuffix}";
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
          IPv4ReversePathFilter = "no"; # required if sysctl item `net.ipv4.conf.default.rp_filter` is not 0
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
    sops.secrets = lib.concatMapAttrs generateSopsAccess cfg.peers;
    systemd.network = lib.concatMapAttrs generateNetworkdConfig cfg.peers;
  };
}
