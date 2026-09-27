# Isolated shell session

The verification compositor is a private Sway. Its socket, the Quickshell process, and the scratch config are the only session this skill is allowed to touch.

## Sub-features

- Read the live Quickshell command line and `QS_WORK_FIXTURE` from its environment.
- Record the Wayland socket and Sway IPC socket.
- Fail if either socket sits outside this run's scratch runtime, if `result` appeared, or if the user quickshell unit is active.

## How to get to it (user POV)

A person sitting at the machine has their own Sway, often with `WAYLAND_DISPLAY` already set, and NixOS may start `quickshell.service` for that graphical session. This check is the opposite path: a second, headless compositor whose sockets live under `.cursor/skills/verify-quickshell/scratch/runtime`, started only for the run and stopped by cleanup. Nothing is activated on the host.

## Driving it with verify-quickshell

```bash
.cursor/skills/verify-quickshell/bin/verify-quickshell launch
.cursor/skills/verify-quickshell/bin/verify-quickshell doctor
.cursor/skills/verify-quickshell/bin/verify-quickshell drive shell-isolated-session
```

The drive runs `session-assert` and `session-isolation`. `session.txt` names the pids and sockets. `isolation.txt` must contain `git-status: unchanged`, `swaysock-under-scratch: yes`, and `wayland-under-scratch: yes`.

## Gotchas

- Launch exits before starting anything when `WAYLAND_DISPLAY` or `SWAYSOCK` is set, or when `pgrep` already sees `quickshell` or `sway`. Clear those variables in the calling shell; do not point the skill at the existing socket.
- Cleanup will not signal a pid whose command line lost the scratch marker. Orphaned processes then have to be stopped by the same command line check, not by `killall sway`.
- `systemctl --user start quickshell` is out of scope. `systemd-user-quickshell: active` fails the drive.
