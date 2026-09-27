---
name: verify-quickshell
description: Verify the real desk-bars Quickshell by running modules/apps/quickshell under an isolated headless Sway session. Use when checking that the shell paints, that the work chip opens the Agents panel, or that the session stays off the user's compositor and systemd. Do not use the HTML prototype.
---

# Verify Quickshell

This skill drives the real Quickshell process (`quickshell -p` on `modules/apps/quickshell/shell.qml`, ShellId `desk-bars`). It starts its own headless Sway, points the shell at that socket, and tears down only processes whose command lines contain this run's scratch directory. It does not start `systemd --user` quickshell, does not `switch` or `deploy` a machine, and does not open `modules/apps/quickshell.prototype.html` or `docs/quickshell/quickshell.prototype.html`.

`Runtime.qml` and `StylixPalette.qml` are written at launch with the same property names as `modules/apps/quickshell/default.nix`. Secret paths, the herdr socket, and the agent-usage script stay empty or point at local stubs, so evaluation never decrypts secrets and the shell never dials herdr. Work data comes from the module's own `QS_WORK_FIXTURE` selector (`FixtureSource.qml`). The QML that paints the bars and opens the panel is the repository copy.

Run the helper from any working directory. Paths below are relative to the flake root. After a repository change that moves a bar, a popup, or the fixture selector, re-prove one live feature with `/maintain-verification-skill`.

## Launch

```bash
.cursor/skills/verify-quickshell/bin/verify-quickshell launch
```

Launch refuses when `WAYLAND_DISPLAY` or `SWAYSOCK` is already set, and when any `quickshell` or `sway` process is already running. It does not attach to that session and it does not kill it.

On success it builds a tool environment from this flake's nixpkgs (`quickshell`, `sway`, `grim`, Mesa llvmpipe, and Wayland headers), compiles `bin/pointer-click.c` with the system `gcc`, copies `modules/apps/quickshell` into the scratch config, and starts headless Sway at 1920x1080 plus `quickshell --no-color -p <scratch>/config` with `QS_WORK_FIXTURE=flights`. Software GL is required (`LIBGL_ALWAYS_SOFTWARE=1`, `GALLIUM_DRIVER=llvmpipe`). A second launch without cleanup fails.

Ready line:

```text
verify-quickshell: ready run=<UTC>-<pid> mode=live
```

## Doctor

```bash
.cursor/skills/verify-quickshell/bin/verify-quickshell doctor
```

Doctor is read-only. Exit 0 when the scratch Sway socket and Quickshell pid are alive, the log contains `Configuration Loaded` and `Shell ID: "desk-bars"`, and no other compositor is running. Exit 1 otherwise. Pipewire, UPower, and portal warnings in the log are expected and are not a failure.

`worth-driving` lists:

- `work-fixture-flights`
- `work-fixture-empty`
- `shell-isolated-session`
- `qml-shell-entrypoint`

## Drive

Drive one feature end to end. The live proof is the flights chip:

```bash
.cursor/skills/verify-quickshell/bin/verify-quickshell drive work-fixture-flights
```

That restarts only this run's Quickshell with `QS_WORK_FIXTURE=flights`, screenshots the closed bars, clicks the bottom-bar work chip at `(1860, 1065)` with an output-bound virtual pointer, and screenshots again. The Agents panel is the tall popup above the right end of the bottom bar. The drive fails if that region stays empty.

Other mapped drives:

```bash
.cursor/skills/verify-quickshell/bin/verify-quickshell drive work-fixture-empty
.cursor/skills/verify-quickshell/bin/verify-quickshell drive shell-isolated-session
.cursor/skills/verify-quickshell/bin/verify-quickshell drive qml-shell-entrypoint
```

`drive prototype` and any path ending in `quickshell.prototype.html` are refused.

Passing line:

```text
verify-quickshell: drove <feature-id> run=<run-id> evidence=<evidence-dir>
```

## Evidence

Each drive writes `.cursor/skills/verify-quickshell/evidence/<run-id>/<feature-id>/`.

Live features include `before.png`, `after.png`, `pixels.txt`, `qs.log`, `fixture.txt`, `quickshell-cmdline.txt`, `session.txt`, and `isolation.txt`. The entrypoint feature includes the `ShellId` grep and the live log line. Isolation must record `git-status: unchanged`, `result-symlink: absent`, `foreign-wayland: absent`, and sockets under the scratch runtime. Cleanup does not delete this tree.

## Cleanup

```bash
.cursor/skills/verify-quickshell/bin/verify-quickshell cleanup
```

Cleanup signals the recorded Quickshell and Sway pids only when their command lines still contain this run's config path or `sway.conf`. It then deletes the scratch directory. Evidence remains.

```text
verify-quickshell: cleaned run=<run-id> evidence=<evidence-dir>
```

## Helpers

| Command | What it does |
| --- | --- |
| `.cursor/skills/verify-quickshell/bin/verify-quickshell launch` | Build tools, compile the pointer helper, start isolated Sway and Quickshell |
| `.cursor/skills/verify-quickshell/bin/verify-quickshell doctor` | Report whether that instance is alive |
| `.cursor/skills/verify-quickshell/bin/verify-quickshell drive <feature-id>` | Run every step of one mapped feature |
| `.cursor/skills/verify-quickshell/bin/verify-quickshell step <step-id>` | Run one step; `steps` lists them |
| `.cursor/skills/verify-quickshell/bin/verify-quickshell cleanup` | Stop this run's processes and delete scratch |

`bin/pointer-click.c` is the virtual-pointer client. Launch compiles it to `scratch/pointer-click`. The flights and empty drives invoke `<scratch>/pointer-click 1860 1065 c`, which binds `zwlr_virtual_pointer_v1` to the headless output and sends absolute motion plus a left click. Do not point it at a `WAYLAND_DISPLAY` you did not start.

Feature map: `features/README.md`.
