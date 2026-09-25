{
  flake.modules.nixos.sing-box =
    {
      config,
      lib,
      pkgs,
      ...
    }:
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
        iptables -t mangle -C OUTPUT -m cgroup --path ${lib.escapeShellArg cgroup} -j MARK --set-mark 0x2024 2>/dev/null \
          || iptables -t mangle -A OUTPUT -m cgroup --path ${lib.escapeShellArg cgroup} -j MARK --set-mark 0x2024
      '') (config.netbird.clientCgroups or [ ]);

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
