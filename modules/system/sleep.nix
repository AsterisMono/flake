{ inputs, ... }:
{
  flake.modules.generic.sleep =
    { lib, ... }:
    {
      options.sleep = {
        dimDelay = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = 5 * 60;
          description = "Seconds of inactivity before the screen is dimmed.";
        };

        monitorOffDelay = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = 10 * 60;
          description = "Seconds of inactivity before the outputs are turned off.";
        };

        suspendDelay = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = 15 * 60;
          description = "Seconds of inactivity before the machine is suspended.";
        };

        hibernateDelay = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = 30 * 60;
          description = ''
            Seconds the machine stays suspended before it hibernates. A machine
            that cannot hibernate stays suspended instead, so hibernation is
            only attempted when the machine supports it. When null the machine
            stays suspended until it is woken.
          '';
        };
      };
    };

  flake.modules.nixos.sleep =
    { config, lib, ... }:
    {
      imports = [ inputs.self.modules.generic.sleep ];

      systemd.sleep.settings.Sleep = lib.optionalAttrs (config.sleep.hibernateDelay != null) {
        HibernateDelaySec = "${toString config.sleep.hibernateDelay}s";
      };
    };

  flake.modules.homeManager.sleep =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.sleep;

      lock = "${lib.getExe config.programs.swaylock.package} -f";
      swaymsg = lib.getExe' config.wayland.windowManager.sway.package "swaymsg";
      brightnessctl = lib.getExe pkgs.brightnessctl;
      systemctl = lib.getExe' pkgs.systemd "systemctl";
      busctl = lib.getExe' pkgs.systemd "busctl";

      outputsOn = "${swaymsg} 'output * dpms on'";
      outputsOff = "${swaymsg} 'output * dpms off'";

      # Logind is the only component that knows whether a resume device and
      # AllowHibernation make hibernation possible, so ask it when the timeout
      # fires. Anything other than a definite yes suspends and stays suspended,
      # rather than failing to sleep at all.
      suspendThenHibernate = pkgs.writeShellApplication {
        name = "suspend-then-hibernate";
        text = ''
          answer="$(${busctl} call org.freedesktop.login1 \
            /org/freedesktop/login1 org.freedesktop.login1.Manager CanHibernate \
            2>/dev/null || true)"

          if [[ "$answer" == *'"yes"'* ]]; then
            exec ${systemctl} suspend-then-hibernate
          fi

          exec ${systemctl} suspend
        '';
      };

      suspend =
        if cfg.hibernateDelay == null then "${systemctl} suspend" else lib.getExe suspendThenHibernate;

      configuredDelays = builtins.filter (delay: delay != null) [
        cfg.dimDelay
        cfg.monitorOffDelay
        cfg.suspendDelay
      ];
    in
    {
      imports = [ inputs.self.modules.generic.sleep ];

      assertions = [
        {
          assertion = configuredDelays == lib.sort (a: b: a < b) configuredDelays;
          message = "sleep: dimDelay, monitorOffDelay and suspendDelay must be in non-decreasing order";
        }
      ];

      # Idle never locks the session. Closing the laptop lid is the only
      # automatic lock, and a machine without a lid switch never fires the
      # binding, so a desktop is never locked by this module.
      wayland.windowManager.sway.config.bindswitches."lid:on".action = "exec ${lock}";

      services.swayidle = {
        enable = true;
        events.after-resume = outputsOn;
        timeouts = lib.flatten [
          # Machines without a backlight have nothing to dim, and a machine
          # where brightnessctl cannot help should not fail the timeout.
          (lib.optional (cfg.dimDelay != null) {
            timeout = cfg.dimDelay;
            command = "${brightnessctl} --save set 10% 2>/dev/null || true";
            resumeCommand = "${brightnessctl} --restore 2>/dev/null || true";
          })
          (lib.optional (cfg.monitorOffDelay != null) {
            timeout = cfg.monitorOffDelay;
            command = outputsOff;
            resumeCommand = outputsOn;
          })
          (lib.optional (cfg.suspendDelay != null) {
            timeout = cfg.suspendDelay;
            command = suspend;
          })
        ];
      };

      systemd.user.services.swayidle.Unit.ConditionEnvironment = lib.mkForce [
        "WAYLAND_DISPLAY"
        "XDG_SESSION_DESKTOP=sway"
      ];
    };
}
