# Desk bars

Desk bars are the full-width top and bottom edges of the shell. The top edge carries the clock and status cluster. The bottom edge carries workspaces and window tasks. Each bar reserves its own strip of the output.

## Sub-features

- `bars-map` reserves 30px at the top and bottom of the output. Workspace 1 then starts at y=30 and is 60px shorter than the output.
- `bars-read` shows the clock on the top bar. In a scaffold session the identity text includes `scaffold`.
- `bars-second-output` applies that same inset on a second headless output.

## How to get to it (user POV)

- Log into the Sway session on a machine whose Home Manager enables quickshell (`stylix-test`, or a workstation such as `parallax` or `asymmetry`). The user service starts the shell when `WAYLAND_DISPLAY` and `XDG_SESSION_DESKTOP=sway` are set.
- For a verification session that is not that login, launch this harness. The bars appear on the headless output with no further click.

## Driving it with verify-quickshell

Preconditions:

- `verify-quickshell doctor` prints `doctor=ok`.
- Launch used the default `--outputs 1`, or relaunch with `--outputs 2` before the second-output bullet.

- **Both bars on one output.** Run `.cursor/skills/verify-quickshell/bin/verify-quickshell drive desk-bars`. `evidence/desk-bars/bars.png` is a PNG. `bars.ocr.txt` contains `Sep` or `scaffold`. Doctor's `bar-insets.txt` is `1`.
- **Second output.** Stop the session with cleanup, then launch again with `.cursor/skills/verify-quickshell/bin/verify-quickshell launch --outputs 2 --fixture ''`. Run doctor. `bar-insets.txt` is `2`. This is a separate launch; do not mix its evidence with the one-output run.

## Gotchas

- Headless sway does not load the SwayFX `layer_effects` blocks. A sharp bar is not a failed glass material. Do not claim blur from this session.
- Scaffold `Runtime.qml` sets `quickshellVersion` to `scaffold`. Identity text that says `scaffold` means the Home Manager config was not the one on screen.
- The systemd user unit is not started by the harness. A passing `lswt` does not prove `ConditionEnvironment`.
- Bar height is 30 logical pixels. The workspace inset is the handle. OCR of the resting bar needs the contrast stretch the harness applies; a raw tesseract run on the black frame is empty.
- `lswt` will not list `quickshell-bar-top`. Do not treat an empty `lswt` listing as missing bars.
- Two outputs in one launch share models. Counts of agents or notifications must not double. This feature only counts bar surfaces.
