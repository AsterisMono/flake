{
  flake.modules.nixos.sing-box =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # xt_cgroup resolves --path when the rule is inserted. firewall.service
      # runs at sysinit, before a NetBird client has a cgroup, and a missing
      # path is rejected with EINVAL (kernel: "xt_cgroup: invalid path,
      # errno=-2"). firewall-start uses `set -e`, so that one append takes the
      # whole firewall down. Skip the mark until the cgroup exists, and install
      # it from the client unit before the daemon runs.
      netbirdCgroups = config.netbird.clientCgroups or [ ];
      iptables = "${pkgs.iptables}/bin/iptables";
      mark = "0x2024";

      ensureNetbirdMark = pkgs.writeShellScript "sing-box-netbird-mark" ''
        set -euo pipefail
        cgroup=$1
        mode=''${2:-optional}
        if [[ ! -d /sys/fs/cgroup/$cgroup ]]; then
          if [[ $mode == require ]]; then
            echo "sing-box: NetBird cgroup $cgroup does not exist" >&2
            exit 1
          fi
          exit 0
        fi
        ${iptables} -w -t mangle -C OUTPUT -m cgroup --path "$cgroup" -j MARK --set-mark ${mark} 2>/dev/null \
          || ${iptables} -w -t mangle -A OUTPUT -m cgroup --path "$cgroup" -j MARK --set-mark ${mark}
      '';

      clearNetbirdMark = pkgs.writeShellScript "sing-box-netbird-unmark" ''
        set -euo pipefail
        cgroup=$1
        ${iptables} -w -t mangle -D OUTPUT -m cgroup --path "$cgroup" -j MARK --set-mark ${mark} 2>/dev/null || true
      '';
    in
    {
      # sing-box publishes the tun as the interface resolver through
      # systemd-resolved (dns_mode "hijack" -> SetLinkDNS with domain "~."), so
      # without resolved nothing points the system at the tun and DNS keeps
      # going to whatever DHCP handed out.
      services.resolved.enable = true;

      # resolved only accepts those SetLinkDNS/SetDomains/SetDefaultRoute calls
      # from the sing-box user when polkit applies the rule shipped in the
      # sing-box package. Without it they fail with "Access denied" and sing-tun
      # discards the error, leaving the tun without a resolver.
      security.polkit.enable = true;

      # sing-tun also calls resolve1.revert when the tun goes away, which the
      # packaged rule does not cover; grant it so that call is not denied too.
      security.polkit.extraConfig = ''
        // systemd-resolved access for the sing-box tun
        polkit.addRule(function(action, subject) {
          var actions = [
            "org.freedesktop.resolve1.revert",
            "org.freedesktop.resolve1.set-default-route",
            "org.freedesktop.resolve1.set-dns-servers",
            "org.freedesktop.resolve1.set-domains",
          ];
          if (actions.indexOf(action.id) >= 0 && subject.user == "sing-box") {
            return polkit.Result.YES;
          }
        });
      '';

      # NetBird's own WireGuard, STUN and relay traffic does not survive being
      # proxied, and the tun's exclude_interface only covers packets that arrive
      # on the NetBird interface. Stamping everything the NetBird clients send
      # with sing-box's auto_redirect output mark (0x2024) instead makes sing-box
      # skip those packets in the redirection and routing paths alike.
      networking.firewall.extraCommands = lib.concatMapStrings (cgroup: ''
        ${ensureNetbirdMark} ${lib.escapeShellArg cgroup}
      '') netbirdCgroups;

      # `+` runs the hook as root, outside the client's User= and
      # ProtectSystem=, so it can update the mangle table. The cgroup already
      # exists here: systemd creates it before ExecStartPre.
      systemd.services = lib.listToAttrs (
        map (cgroup: {
          name = lib.removeSuffix ".service" (baseNameOf cgroup);
          value = {
            serviceConfig = {
              ExecStartPre = [ "+${ensureNetbirdMark} ${cgroup} require" ];
              ExecStopPost = [ "+${clearNetbirdMark} ${cgroup}" ];
            };
          };
        }) netbirdCgroups
      );

      sops.secrets.sing_box_config = {
        format = "json";
        sopsFile = config.constants.resources.getSecretPath "sing-box.json";
        path = "/etc/sing-box/config.json";
        key = "";
        restartUnits = [ "sing-box.service" ];
      };
      services.sing-box = {
        enable = true;
        package = pkgs.unstable.sing-box;
      };
    };
}
