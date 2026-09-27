# QML shell entrypoint

`modules/apps/quickshell/shell.qml` is the file Quickshell loads. The running process must be that file, and the log must report the same ShellId the pragma declares.

## Sub-features

- Read `//@ pragma ShellId desk-bars` and `ShellRoot` from the repository `shell.qml`.
- Compare that file with the scratch copy the process was given.
- Read `Shell ID: "desk-bars"` and `Configuration Loaded` from the live log.

## How to get to it (user POV)

Quickshell's config directory is what `quickshell -p` loads. On a machine, Home Manager points `programs.quickshell.configs.desk` at the generated directory whose entry is this `shell.qml`. The visible shell is the `ShellRoot` inside it: one `Bar` per screen plus the popup hosts. The log line `Shell ID: "desk-bars"` is the same identifier the pragma sets, which is how you know which config came up.

## Driving it with verify-quickshell

```bash
.cursor/skills/verify-quickshell/bin/verify-quickshell launch
.cursor/skills/verify-quickshell/bin/verify-quickshell doctor
.cursor/skills/verify-quickshell/bin/verify-quickshell drive qml-shell-entrypoint
```

The drive runs `qml-source` and `qml-isolation`. Evidence files `shellid.txt`, `shellroot.txt`, `live-shell-id.txt`, and `live-loaded.txt` hold the matching lines. `source-match.txt` says `matches-running-config: yes`.

## Gotchas

- This feature does not click the bar. A log line without `work-fixture-flights` does not show that the panel opens.
- `Runtime.qml` is not compared to a store path. It is launch scaffolding with empty secret paths. `shell.qml` and the rest of the QML tree are the repository files.
- `default.nix` is removed from the scratch copy so the running directory is a Quickshell config, not a Nix module.
