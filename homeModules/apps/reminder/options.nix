{ config, lib, ... }:
let
  inherit (lib) mkOption types;
  cfg = config.noa.reminders;
  reminderOpts = _: {
    options = {
      OnCalendar = mkOption {
        example = [ "*-*-* 4:00:00" ];
        type = with types; listOf str;
      };
      ExecStart = mkOption {
        example = ''
          notify-send "Hello world!"
        '';
        type = types.str;
      };
    };
  };
  generateSystemdServices =
    reminderAttrs:
    lib.mapAttrs' (
      name: value:
      lib.nameValuePair "reminder-${name}" {
        Unit = {
          Description = "Reminder service for ${name}";
        };
        Service = {
          Type = "oneshot";
          inherit (value) ExecStart;
        };
      }
    ) reminderAttrs;
  generateSystemdTimers =
    reminderAttrs:
    lib.mapAttrs' (
      name: value:
      lib.nameValuePair "reminder-${name}" {
        Unit = {
          Description = "Reminder timer for ${name}";
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
        Timer = {
          inherit (value) OnCalendar;
        };
      }
    ) reminderAttrs;
in
{
  options = {
    noa.reminders = mkOption {
      example = {
        "estrofem-intake" = {
          OnCalendar = [ "*-*-* 15:00:00" ];
          ExecStart = ''
            notify-send -u critical -i /home/cmiki/Pictures/estrofem.png "HRT Reminder" "Time for an estrofem intake"
          '';
        };
      };
      type = with types; attrsOf (submodule reminderOpts);
    };
  };

  config = {
    systemd.user = {
      services = generateSystemdServices cfg;
      timers = generateSystemdTimers cfg;
    };
  };
}
