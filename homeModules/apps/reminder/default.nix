{
  pkgs,
  lib,
  assetsPath,
  ...
}:
let
  getReminderIcon = filename: "${assetsPath}/reminder-icons/${filename}";
  notify-send = lib.getExe' pkgs.libnotify "notify-send";
in
{
  imports = [ ./options.nix ];

  noa.reminders = {
    "estrofem-intake" = {
      OnCalendar = [
        "*-*-* 07:00:00"
        "*-*-* 15:00:00"
        "*-*-* 23:00:00"
      ];
      ExecStart = ''
        ${notify-send} -u critical -i ${getReminderIcon "estrofem.png"} "HRT Reminder" "Time for an estrofem intake"
      '';
    };
    "androcur-intake" = {
      OnCalendar = [
        "*-*-* 22:00:00"
      ];
      ExecStart = ''
        ${notify-send} -u critical -i ${getReminderIcon "androcur.png"} "HRT Reminder" "Time to check for an androcur intake"
      '';
    };
    "escitalopram-intake" = {
      OnCalendar = [
        "*-*-* 13:30:00"
      ];
      ExecStart = ''
        ${notify-send} -u critical -i ${getReminderIcon "escitalopram.png"} "Medication Reminder" "Time for an escitalopram intake"
      '';
    };
    "lorazepam-intake" = {
      OnCalendar = [
        "*-*-* 08:30:00"
      ];
      ExecStart = ''
        ${notify-send} -u critical -i ${getReminderIcon "lorazepam.png"} "Medication Reminder" "Time for a lorazepam intake"
      '';
    };
  };
}
