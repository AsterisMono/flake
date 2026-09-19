{ inputs, ... }:
{
  flake.modules.generic.sleep =
    { lib, ... }:
    {
      options.sleep = {
        lockDelay = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = 5 * 60;
          description = ''
            Seconds of inactivity before the session is locked. The session
            still locks before suspending when this is null.
          '';
        };

        monitorOffDelay = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = 30 * 60;
          description = "Seconds of inactivity before the outputs are turned off.";
        };

        suspendDelay = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = 60 * 60;
          description = "Seconds of inactivity before the machine is suspended.";
        };

        hibernateDelay = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = 60 * 60;
          description = ''
            Seconds the machine stays suspended before hibernating. When null
            it stays suspended until it is woken instead.
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
      systemctl = lib.getExe' pkgs.systemd "systemctl";
      outputsOn = "${swaymsg} 'output * dpms on'";
      configuredDelays = builtins.filter (delay: delay != null) [
        cfg.lockDelay
        cfg.monitorOffDelay
        cfg.suspendDelay
      ];
    in
    {
      imports = [ inputs.self.modules.generic.sleep ];

      assertions = [
        {
          assertion = configuredDelays == lib.sort (a: b: a < b) configuredDelays;
          message = "sleep: lockDelay, monitorOffDelay and suspendDelay must be in non-decreasing order";
        }
      ];

      services.swayidle = {
        enable = true;
        events = {
          before-sleep = lock;
          after-resume = outputsOn;
        };
        timeouts = lib.flatten [
          (lib.optional (cfg.lockDelay != null) {
            timeout = cfg.lockDelay;
            command = lock;
          })
          (lib.optional (cfg.monitorOffDelay != null) {
            timeout = cfg.monitorOffDelay;
            command = "${swaymsg} 'output * dpms off'";
            resumeCommand = outputsOn;
          })
          (lib.optional (cfg.suspendDelay != null) {
            timeout = cfg.suspendDelay;
            command =
              if cfg.hibernateDelay == null then
                "${systemctl} suspend"
              else
                "${systemctl} suspend-then-hibernate";
          })
        ];
      };

      systemd.user.services.swayidle.Unit.ConditionEnvironment = lib.mkForce [
        "WAYLAND_DISPLAY"
        "XDG_SESSION_DESKTOP=sway"
      ];
    };
}
