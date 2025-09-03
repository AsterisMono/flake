{
  config,
  lib,
  secretsPath,
  assetsPath,
  pkgs,
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
  ownAsOpts = _: {
    options = {
      asn = mkOption {
        example = "AS4242420833";
        type = types.str;
        description = ''
          Your AS number in the DN42 network.
        '';
      };
      routerIp = mkOption {
        example = "fdec:a476:db6e::1";
        type = types.str;
        description = ''
          The ipv6 address of your router. (IPv6 Only)
        '';
      };
      routerId = mkOption {
        example = "224.6.107.225";
        type = types.str;
        description = ''
          Your router id (typically the IPv4 address of the router).
          In case of a IPv6 only network, choose a unique number in your AS.

          See:
          https://www.rfc-editor.org/rfc/rfc6286
          https://networkengineering.stackexchange.com/questions/510/how-to-choose-a-bgp-router-id-when-using-ipv6-only
        '';
      };
      subnet = mkOption {
        example = "fdec:a476:db6e::/48";
        type = types.str;
        description = ''
          The subnet you own in the DN42 network. (IPv6 Only)
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
      asInfo = mkOption {
        description = "Info about your own AS.";
        default = null;
        type = types.submodule ownAsOpts;
        example = {
          asn = "AS4242420833";
          routerIp = "fdec:a476:db6e::fade:cafe";
          routerId = "224.6.107.225";
          subnet = "fdec:a476:db6e::/48";
        };
      };
      waitForInterface = mkOption {
        description = "Wait for a specific interface to come online before starting tunnels";
        type = types.str;
        default = null;
        example = "enu1";
      };
      peers = mkOption {
        description = "DN42 Peers";
        default = { };
        type = with types; attrsOf (submodule peerOpts);
        example = {
          "AS4242422323" = {
            endpoint = "home.kagura.lolicon.cyou:20833";
            pubkey = "z3XndJnzBW9D+S6flQ+nlJH+WlrCcGtImdN4kUb/LGM=";
            tunnelLocalAddr = "fe80::fade:cafe/64";
            tunnelPeerAddr = "fe80:759::2323/64";
          };
        };
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
    systemd.network =
      let
        dummyIfname = "dn42dummy0";
      in
      lib.recursiveUpdate (lib.concatMapAttrs generateNetworkdConfig cfg.peers) {
        netdevs."${dummyIfname}" = {
          netdevConfig = {
            Name = dummyIfname;
            Kind = "dummy";
          };
        };
        networks."dn42" = {
          matchConfig = {
            Name = dummyIfname;
          };
          networkConfig = {
            Address = [ cfg.asInfo.routerIp ];
          };
        };
      };
    networking.firewall =
      let
        asns = lib.attrNames cfg.peers;
      in
      {
        trustedInterfaces = map mkDn42WgIfname asns;
        allowedUDPPorts = map mkDn42WgPort asns;
      };

    # Bird
    services.bird =
      let
        initialRoa = "${assetsPath}/dn42/dn42_roa_bird2_6.conf";
      in
      {
        enable = true;
        package = pkgs.bird2;
        config =
          let
            inherit (cfg) asInfo;
          in
          ''
            ################################################
            #               Variable header                #
            ################################################

            define OWNAS = ${lib.removePrefix "AS" asInfo.asn};
            define OWNIP = ${asInfo.routerIp};
            define OWNNET = ${asInfo.subnet};
            define OWNNETSET = [${asInfo.subnet}+];

            ################################################
            #                 Header end                   #
            ################################################

            log syslog { warning, error, fatal };
            log "/var/log/bird/remote.log" { remote };
            log "/var/log/bird/bugs.log" { bug };
            log "/var/log/bird/trace.log" { trace };
            log "/var/log/bird/debug.log" { debug };
            log "/var/log/bird/info.log" { info };

            router id ${asInfo.routerId};

            protocol device {
                scan time 10;
            }

            /*
              *  Utility functions
              */

            function is_self_net() -> bool {
              return net ~ OWNNETSET;
            }

            roa6 table dn42_roa;

            protocol static {
                roa6 { table dn42_roa; };
                include "${initialRoa}";
            };

            function is_valid_network() -> bool {
              return net ~ [
                fd00::/8{44,64} # ULA address space as per RFC 4193
              ];
            }

            protocol kernel {
                scan time 20;

                ipv6 {
                    import none;
                    export filter {
                        if source = RTS_STATIC then reject;
                        krt_prefsrc = OWNIP;
                        accept;
                    };
                };
            };

            protocol static {
                route OWNNET reject;

                ipv6 {
                    import all;
                    export none;
                };
            }

            template bgp dnpeers {
                local as OWNAS;
                path metric 1;

                ipv6 {   
                    import filter {
                      if is_valid_network() && !is_self_net() then {
                        if (roa_check(dn42_roa, net, bgp_path.last) != ROA_VALID) then {
                          # Reject when unknown or invalid according to ROA
                          print "[dn42] ROA check failed for ", net, " ASN ", bgp_path.last;
                          reject;
                        } else accept;
                      } else reject;
                    };
                    export filter { if is_valid_network() && source ~ [RTS_STATIC, RTS_BGP] then accept; else reject; };
                    import limit 9000 action block; 
                };
            }

            ${
              # FIXME: the interface suffix (for fe80 local-links) is ignored for now.
              lib.concatLines (
                lib.mapAttrsToList (asn: values: ''
                  protocol bgp dn42_${lib.toLower asn} from dnpeers {
                      neighbor ${lib.head (lib.splitString "/" values.tunnelPeerAddr)} as ${lib.removePrefix "AS" asn};
                      direct;
                      ipv4 {
                        import none;
                        export none;
                      };
                  }
                '') cfg.peers
              )
            }
          '';
      };

    systemd.tmpfiles.settings = {
      "10-birdlogs" = {
        "/var/log/bird" = {
          d = {
            user = "bird";
            group = "bird";
            mode = "0755";
          };
        };
      };
    };

    noa.tailscale = {
      advertiseTags = [ "dn42" ];
      advertiseRoutes = [ "fd00::/8" ];
    };
  };

  # TODO: automatic ROA updates.
}
