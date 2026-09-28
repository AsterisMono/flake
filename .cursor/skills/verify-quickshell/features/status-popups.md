# Calendar, audio, and power

Calendar, audio, and power are ordinary popups opened from the top bar. The clock opens the calendar. The audio control opens output volume. The power control opens profiles and Keep awake. Only one popup is open at a time.

## Sub-features

- `popup-clock` opens the calendar from the clock and shows the current month.
- `popup-audio` opens output controls from the audio control.
- `popup-power` opens Keep awake and the power profile list from the power control.
- `popup-one` replaces an open popup instead of stacking a second interactive panel.

## How to get to it (user POV)

- Choose the clock on the left of the top bar. The calendar opens under it. Choose `Back to today` after moving a month, or press Escape, or click outside the panel.
- Choose the audio control in the right-hand cluster. Scroll changes volume by 1 percent. Middle-click mutes. `Open mixer` is the pavucontrol escape hatch.
- Choose the power or battery control in that cluster. Keep awake offers `30 min`, `1 hour`, and `Until off`.

## Driving it with verify-quickshell

Preconditions:

- `verify-quickshell doctor` prints `doctor=ok`.
- The output is 1920×1080 at scale 1, which is the harness sway config.
- Locale for OCR is whatever the session inherited. The calendar assertion accepts `September` or `Back to today`.

- **Calendar, audio, or power.** Run `.cursor/skills/verify-quickshell/bin/verify-quickshell drive status-popups --kind clock` (or `audio`, or `power`). The command exits non-zero and writes `evidence/status-popups-<kind>/blocker.txt`. That file is the result. It is not a pass. A machine that can click a pixel would instead show a popup whose text is `September` or `Back to today` for the clock, `Output device` or `Open mixer` for audio, and `Keep awake` or `Power profile` for power.

## Gotchas

- Clicks are not available with `wlrctl` 0.2.2 or without `/dev/uinput`. Do not retarget the drive by editing QML, and do not report the blocker file as a passed popup.
- A headless VM has no battery and no real backlight. The power popup may say the performance profile is unavailable. That sentence is an honest reading, not a failed drive, as long as `Keep awake` or `Power profile` is visible. Do not click `Until off` during verification: Keep awake inhibits idle on the bar surface.
- `Open mixer` and `Open system monitor` launch host programs. This drive stops at the visible control. Do not click them.
- Audio scroll and middle-click mute are not driven. There is no PipeWire graph required for the popup text, and a mute click would be a real device change when the module config is used on a workstation.
- Opening a second kind closes the first. Drive one kind, let the harness press Escape, then drive the next.
