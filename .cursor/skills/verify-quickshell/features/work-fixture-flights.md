# Work fixture flights

The bottom bar's work chip summarizes herdr stand-in agents and opens the Agents panel. With `QS_WORK_FIXTURE=flights` the module's `FixtureSource.qml` supplies five sample agents, and `WorkSummary.qml` turns them into the chip the bar actually paints.

## Sub-features

- Reload this run's Quickshell with `QS_WORK_FIXTURE=flights`.
- Screenshot the closed shell and require both bars on a black center.
- Click the right end of the bottom bar at `(1860, 1065)`.
- Require the tall Agents popup in the upper-right of the frame.

## How to get to it (user POV)

On a Sway session the desk-bars shell is already on screen. The bottom bar's right-hand chip reads counts such as "1 working", "2 idle", and "2 need you". Clicking that chip opens the Agents panel over the wallpaper. Closing it is the same chip again. This check rebuilds that path in a compositor the skill owns, because it must not type into the user's existing `WAYLAND_DISPLAY` or start the systemd user unit.

## Driving it with verify-quickshell

```bash
.cursor/skills/verify-quickshell/bin/verify-quickshell launch
.cursor/skills/verify-quickshell/bin/verify-quickshell doctor
.cursor/skills/verify-quickshell/bin/verify-quickshell drive work-fixture-flights
```

The drive runs `flights-reload`, `flights-before`, `flights-click`, `flights-after`, `flights-assert`, and `flights-isolation`. `pixels.txt` must show `popup-closed 0 eq 0` on `before.png` and `flights-popup-upper` greater than 20000 on `after.png` for the rectangle `x=1480..1910`, `y=250..760`. `fixture.txt` is `flights`. `qs.log` contains `Shell ID: "desk-bars"` and `Configuration Loaded`.

## Gotchas

- The click is absolute on the 1920x1080 headless output. A layout change that moves the work chip off `(1860, 1065)` fails the popup pixel check instead of hitting a different control.
- `Runtime.qml` in the scratch config is generated scaffolding. The panel layout is still `popups/WorkPopup.qml` from the repository. Herdr is not contacted; the fixture is the module's offline source.
- Pipewire and UPower errors in `qs.log` do not fail this feature. An empty popup region does.
- Do not satisfy this feature by opening `quickshell.prototype.html`.
