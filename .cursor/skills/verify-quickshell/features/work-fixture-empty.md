# Work fixture empty

`QS_WORK_FIXTURE=empty` is the module's online session with no agents. The work chip stays visible and the Agents panel opens without the flight rows.

## Sub-features

- Reload this run's Quickshell with `QS_WORK_FIXTURE=empty`.
- Screenshot the closed shell and require both bars on a black center.
- Click the right end of the bottom bar at `(1860, 1065)`.
- Require a short panel: pixels in the upper popup band stay zero, and the lower band fills in.

## How to get to it (user POV)

The same bottom-bar work chip is on screen when herdr has no agents to report. The chip's quiet line is "no agents". Clicking it still opens Agents, and the list of flights is absent, so the panel sits lower and shorter than the flights panel. Account rows can still render; they are not agent rows.

## Driving it with verify-quickshell

```bash
.cursor/skills/verify-quickshell/bin/verify-quickshell launch
.cursor/skills/verify-quickshell/bin/verify-quickshell doctor
.cursor/skills/verify-quickshell/bin/verify-quickshell drive work-fixture-empty
```

The drive runs `empty-reload`, `empty-before`, `empty-click`, `empty-after`, `empty-assert`, and `empty-isolation`. `fixture.txt` is `empty`. On `after.png`, `empty-popup-upper` is `0` for `y=250..760`, and `empty-popup-lower` is greater than 15000 for `y=800..1048`.

## Gotchas

- A flights panel also covers the lower band. The upper-band zero count is what separates this fixture from `work-fixture-flights`.
- Restarting Quickshell drops the previous panel. The drive always reloads so the before screenshot is closed.
- The click misses if the chip is no longer anchored to the right edge of a 1920-wide bottom bar.
