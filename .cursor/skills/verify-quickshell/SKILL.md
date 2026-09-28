---
name: verify-quickshell
description: "Drive the desk-bars Quickshell (QML under modules/apps/quickshell) in an isolated headless Wayland session and capture layer-shell evidence. Use when proving bars, popups, the notification center, or Work in flight; do not treat the HTML prototypes as the running shell."
---

# Verify Quickshell

The surface is the live shell: `modules/apps/quickshell/shell.qml` and the bars, popups, and `work/` modules it instantiates. Home Manager wires it in `modules/apps/quickshell/default.nix` as `programs.quickshell.configs.desk`, started by the user service when `WAYLAND_DISPLAY` is set and `XDG_SESSION_DESKTOP=sway`.

These files are design artifacts, not the running app:

- `docs/quickshell/quickshell.prototype.html`
- `modules/apps/quickshell.prototype.html`
- `docs/quickshell/0001-v1-core-shell.md` and `0002-v2-work-in-flight.md` (they specify behavior; they are not a session)

There is no Playwright suite and no Quickshell IPC. The drive path is an isolated compositor plus the real QML:

1. A private `XDG_RUNTIME_DIR` and a private session bus, so the shell cannot grab the user's `org.freedesktop.Notifications` or Sway socket.
2. Headless `sway` (`WLR_BACKENDS=headless`, pixman). This is stock `sway` from the flake's nixpkgs, not SwayFX. Namespaces and text can be proven. `layer_effects` blur in `modules/apps/sway.nix` cannot.
3. `quickshell -p <config>` with `QS_WORK_FIXTURE` when the feature needs herdr sample data.
4. `grim` for a screenshot and `tesseract` after an ImageMagick contrast stretch. The bars are 40% glass on a black headless frame, and raw OCR reads an empty page. `lswt` is recorded, but version 2.0 lists toplevels and does not list layer-shell namespaces.

The stable bar observation is the Sway workspace rectangle: with both bars mapped, workspace 1 sits at y=30 and its height is the output height minus 60. The stable text observation is the OCR of that frame.

Clicks are not used. `wlrctl` 0.2.2 from this flake's nixpkgs only emits relative pointer motion, and `ydotoold` needs `/dev/uinput`, which a typical cloud VM does not have. Popups and the notification bell are clicks. This harness records that blocker instead of inventing a click. The work-in-flight summary is text on the bottom bar and does not need one.

The shell has no second instance policy beyond the compositor socket. Two verifications must not share an `XDG_RUNTIME_DIR`. The harness refuses to drive a `WAYLAND_DISPLAY` it did not start.

Account usage inside the work panel runs `quickshell-agent-usage`, which reads API key files and can call account endpoints. This harness rewrites those paths to a stub that prints `{"ok":false}` and exits. It will not run with `VERIFY_QUICKSHELL_LIVE_ACCOUNTS=1`. Herdr's socket is left blank. Fixture mode (`QS_WORK_FIXTURE=flights` and the other scenarios in `work/FixtureSource.qml`) is the repo's own stand-in for a live herdr session.

## Launch

From the repository root:

```sh
.cursor/skills/verify-quickshell/bin/verify-quickshell launch
```

That defaults to `--config scaffold --fixture flights --outputs 1`. Launch is ready when it prints the run directory and `evidence/launch/lswt-ready.txt` lists `quickshell-bar-top` and `quickshell-bar-bottom`.

Scaffold copies `modules/apps/quickshell/*.qml`, writes `StylixPalette.qml` from the Catppuccin Mocha `defaultPalette` in `default.nix`, and writes a `Runtime.qml` whose `quickshellVersion` is the literal `scaffold`. Scaffold proves the QML can map. It does not prove Home Manager's generated paths, Stylix injection, or `quickshell-health`.

To build the real config from a machine that imports quickshell (`stylix-test` does; `parallax` and `asymmetry` do via the workstation role):

```sh
.cursor/skills/verify-quickshell/bin/verify-quickshell launch --config module --machine stylix-test --fixture flights
```

That builds:

```text
.#nixosConfigurations.<machine>.config.home-manager.users.nvirellia.programs.quickshell.configs.desk
```

The module build evaluates that machine and realizes `Runtime.qml`'s tool closures (including waycat and the codex package path). On a small VM, prefer scaffold and say so. The harness still blanks `herdrEndpoint` and the account-usage script after the copy.

Other launch flags:

- `--fixture ''` leaves Work in flight unconfigured (V1 bars, no herdr chip). Scenarios that exist in `FixtureSource.qml`: `flights`, `followup`, `disconnected`, `ended`, `empty`, `incompatible`, `idle`.
- `--outputs 2` sets `WLR_HEADLESS_OUTPUTS=2` so each bar namespace is mapped twice.

The session lives in tmux as `verify-quickshell-<run-id>` until cleanup. Packages come from `nix shell --inputs-from <repo> nixpkgs#quickshell` (and sway, grim, lswt, wlrctl, tesseract, libnotify, foot, jq, dbus). If `nix` is missing, launch stops. Do not open the HTML prototype in a browser and call that the shell.

A managed NixOS host's `systemd --user` unit is not started here. Proving `ConditionEnvironment` of `systemd.user.services.quickshell` means reading it from the evaluated machine, or watching the user unit on that host after a real login. This skill does not `nh os switch` to get there.

## Doctor

```sh
.cursor/skills/verify-quickshell/bin/verify-quickshell doctor
```

Doctor passes only when:

- The run is `ready`.
- The recorded quickshell pid is alive and its `XDG_RUNTIME_DIR` is this run's runtime directory.
- `swaymsg -t get_tree` shows one workspace per launched output whose rectangle starts at y=30 and is 60 pixels shorter than the output. That is the pair of 30px exclusive bars.

It prints `config_source`, whether the herdr endpoint was blanked, and whether account usage is the stub. If `config_source=scaffold`, do not claim the NixOS module was proven.

Doctor re-enters a nix shell when `lswt` is not on the caller's `PATH`, using the same inputs as launch.

## Drive

Drive one feature with the session doctor just accepted:

```sh
.cursor/skills/verify-quickshell/bin/verify-quickshell drive desk-bars
.cursor/skills/verify-quickshell/bin/verify-quickshell drive workspaces-and-tasks
.cursor/skills/verify-quickshell/bin/verify-quickshell drive status-popups --kind clock
.cursor/skills/verify-quickshell/bin/verify-quickshell drive status-popups --kind audio
.cursor/skills/verify-quickshell/bin/verify-quickshell drive status-popups --kind power
.cursor/skills/verify-quickshell/bin/verify-quickshell drive notification-center
.cursor/skills/verify-quickshell/bin/verify-quickshell drive work-in-flight
```

`work-in-flight` requires the launch fixture `flights`. It screenshots the frame and requires OCR of `working` and `need you` (the bottom-bar summary for the flights fixture: 1 working, 2 idle, 2 need you). The focused Sway window id must be unchanged, and `/proc/<pid>/fd` must not mention `herdr.sock`. It writes `panel-blocker.txt` because the panel itself is a click.

`desk-bars` requires the same workspace inset and OCR of `Sep` or `scaffold` (the scaffold runtime's identity string, or the clock's month).

`status-popups` and `notification-center` exit with a blocker file. They are not passes. `workspaces-and-tasks` opens `foot` titled `Verify task` through `swaymsg` and requires that title in the tree and in the OCR.

## Evidence

Artifacts stay in:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/verify-quickshell/runs/<run-id>/evidence/
```

Launch writes `session.log`, `sway.log`, `quickshell.log`, `lswt-ready.txt`, and `config-provenance.txt`. A drive writes its screenshots, OCR text, and `lswt` snapshots under `evidence/<feature>/` (`status-popups-clock`, `status-popups-audio`, `status-popups-power` for the three popup kinds).

A proof names the feature id, `config_source`, and the fixture. Scaffold evidence is proof of the QML session only. Opening the work panel must show the fixture source line `Sample data · fixture mode (flights)`, which is how you see that herdr was not contacted, together with the fd listing.

```sh
.cursor/skills/verify-quickshell/bin/verify-quickshell evidence
```

## Cleanup

```sh
.cursor/skills/verify-quickshell/bin/verify-quickshell cleanup
```

Cleanup kills the tmux session from `meta.env` and any remaining process whose `XDG_RUNTIME_DIR` is that run's runtime directory. It does not kill by process name. It deletes `scratch/`, `config/`, and the runtime directory. It leaves `evidence/`. After cleanup, `evidence/` must still contain the screenshot and OCR from the drive.

## Helpers

The helper is `.cursor/skills/verify-quickshell/bin/verify-quickshell`. It is executable. Invoke it by that path, as the sections above do. With no arguments it prints usage and exits 2.
