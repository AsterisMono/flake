# Quickshell verification map

This directory is the maintained source for verifying the desk-bars Quickshell. Read the index before driving, then use the matching feature file as the recipe.

The running app is the QML shell under `modules/apps/quickshell/`, launched by `verify-quickshell`. The HTML prototypes under `docs/quickshell/` and `modules/apps/` are design artifacts. A browser screenshot of those files is not a result for any feature below.

## Baseline preconditions

- The working directory is the flake checkout.
- `nix` is on `PATH`. The harness takes `quickshell`, `sway`, `grim`, `lswt`, `wlrctl`, `tesseract`, `libnotify`, `foot`, `jq`, and `dbus` from the flake's `nixpkgs` input.
- Launch with `.cursor/skills/verify-quickshell/bin/verify-quickshell launch` unless the feature names different flags.
- Default launch uses a scaffold config and `QS_WORK_FIXTURE=flights` on one 1920×1080 headless output. `doctor` must print `doctor=ok` and show this run's `XDG_RUNTIME_DIR`.
- Do not drive a Wayland display the harness did not start. Do not start the host's systemd user unit as part of a drive.

## Driving conventions

- Start every recipe from the launch session unless its preconditions change fixture, outputs, or config source.
- Stable handles are the Sway workspace rectangle and the visible strings in the feature file. `lswt` 2.0 lists toplevels and does not list `quickshell-bar-*` namespaces, so a namespace grep is not a pass.
- Both bars reserve 30px. On a 1080-tall output the workspace rectangle is y=30 and height=1020.
- Clicks are not available: `wlrctl` 0.2.2 only moves the pointer relatively, and this VM has no `/dev/uinput`. A feature that can only be opened by a click is reported as not driven.
- Run actions through `.cursor/skills/verify-quickshell/bin/verify-quickshell drive …`.
- The compositor is stock headless sway. Blur from SwayFX `layer_effects` is out of scope for this session.
- Account-usage commands and the herdr socket are stubbed. Do not point the drive at real API keys.
- Do not remove proof artifacts during cleanup.

## Proof and skip reporting

- Capture the action (notify-send text, sway window title, click that opened a namespace) and the resulting state (a second `lswt` snapshot, OCR, focused window id).
- A PNG alone is not enough when the feature names a string. Keep the OCR text beside the PNG.
- Record `config_source` from `evidence/launch/config-provenance.txt`. Scaffold does not prove the Home Manager module.
- Record the feature id. Do not report a skipped entry point as verified through a different one.
- Report an unreachable path with the command and the unmet precondition (no `nix`, quickshell failed to map, OCR missed the string, module eval failed).

## Feature entry contract

Each feature file starts with an H1 title and one paragraph describing the user-visible behavior. It then uses exactly four H2 sections in this order.

1. `Sub-features` lists short IDs with one line for each behavior.
2. `How to get to it (user POV)` lists every user entry point.
3. `Driving it with verify-quickshell` starts with `Preconditions:` and uses labeled bullets that pair each user action with an exact command and observable result.
4. `Gotchas` lists traps that can waste or invalidate a verification run.

Keep implementation essays out of the map. Name user paths, namespaces, strings, commands, and observable proof.

## Features

- [Desk bars](./desk-bars.md) covers the top and bottom bars on one output and on a second headless output.
- [Workspaces and tasks](./workspaces-and-tasks.md) covers workspace labels and titled window buttons.
- [Calendar, audio, and power](./status-popups.md) covers the clock, audio, and power popups.
- [Notification center](./notification-center.md) covers a harmless notification and the bell panel.
- [Work in flight](./work-in-flight.md) covers the herdr fixture summary and panel, separate from V1.
