# 0001 — V1: the everyday shell

Status: V1 implemented; live-session acceptance pending.

Recorded: 2026-09-18.

Companion: [0002 — V2: Work in flight and herdr](0002-v2-work-in-flight.md).

## Intent and release boundary

Replace the existing two-bar Waybar setup with a small, coherent Quickshell desktop shell. The concept is **desk bars**: two continuous edges that organize the desktop, with temporary columns opening from them. It should feel like a room someone tends, not a control panel someone operates.

The emotional direction is a quiet workstation, soft technical precision, and a little personal strangeness. Typography, alignment, information hierarchy, and considerate behavior do most of the work. The sky and smoked glass supply atmosphere; individual widgets do not need their own decorative containers.

| Release | Commitment |
| --- | --- |
| V1, this document | Both bars, workspaces and titled window tasks, status and media, calendar, audio, battery/power/Keep awake, notification center, multi-output behavior, and Nix/session integration. |
| V2, document 0002 | Work in flight connected to herdr, using the V1 visual and popup infrastructure. |
| Explored, not selected | Return thread: notes attached to windows. Preserved in the prototype, but not an implementation requirement for either release. |

V1 must be useful and complete without herdr. This is not a one-for-one widget port, nor a broader replacement for the launcher, lock screen, compositor, or session manager.

## Archived design

- [Interactive HTML prototype](quickshell.prototype.html): copied unchanged from the working prototype. Open locally in a browser. Choose “Work in flight,” or the rightmost bell; the default also demonstrates the unselected Return thread exploration.

The prototype was reviewed as a browser render at 1920 × 1080 logical pixels, with prototype controls and the V2/Return thread affordances hidden for the V1 projection. Renders and the generated sky wallpaper are not kept in the repository; the page falls back to its flat backing colour, and the wallpaper's provenance and prompt stay recorded in the HTML comment. It is not a running Quickshell session.

All actions and data in the HTML are simulated and memory-only. Its preview toolbar, alternate layouts, sample jobs, and JavaScript are not production requirements. Preserve it as a design artifact, not a starting application architecture.

### Decisions already made

- Notification layout **C**: the history opened from the rightmost top-bar control. It became an ordinary popup rather than a full-height column: anchored under the top bar, inset from the output's edge like every other popup, sized to its content, and scrollable once it reaches the available height.
- Overall glass option **C**: **40% backing opacity** across both bars and every popup, including the notification panel. Text and icons remain fully opaque. This is a separate choice from notification layout C.
- A sky background and blurred, frosted surfaces. The later explicit request for glass supersedes the earlier preference against gratuitous transparency; it does not call for glossy cards or decorative blur everywhere.
- Power profile and idle inhibition move into the Battery popup. Keep awake gets a small bar indicator only while active.
- Dense but breathable information, global workspaces and individual titled window buttons on both outputs.
- Warm, practical microcopy and reversible local actions. [Piru](https://github.com/kageroumado/piru) informed the care for consequences, continuity, and the person using the interface; no Piru code or assets were copied. The inspected reference was commit `5f6a422`.

The implementation details below are proposed ways of delivering these choices, not claims that the HTML has already solved the live integration.

## Visual system

| Element | Starting specification |
| --- | --- |
| Silhouette | Full-width, flush top and bottom bars; 30 logical px each; each reserves its own space. No floating islands. |
| Material | Smoked charcoal backing, prototype tint `#20212b` at 0.40 alpha, restrained blur and a fine edge. One shared material definition. |
| Text | Warm primary `#e1dad3`, secondary `#b8b0b3`; quieter metadata only where it remains legible. Fira Code for bar/metrics, Noto Sans for longer reading and multilingual fallback. Start at 12 logical px for bar text. |
| Accent | Muted blue-grey `#a0bbc1` for selection; amber for attention and soft red for critical conditions. Most pixels remain neutral. |
| Rhythm | 4 px spacing unit; small groups use 8–12 px; panel reading edges about 20 px. Align icons and numerals to consistent text baselines. |
| Geometry | Mostly square edges, at most 2–4 px corner radius on secondary surfaces; 1 px separators. No pill around every datum. |
| Panels | Notification column about 384 logical px wide; ordinary popups about 340–400 px. Clamp to available output geometry and scroll content, not the entire panel. |
| Motion | Approximately 120–160 ms opacity/position settling, without bounce or glowing pulses. No perpetual activity animation. V1 does not offer a reduced-motion or opaque-surface fallback; motion is already short. |

These are logical sizes, not physical pixels on the 27-inch 4K display. Validate at the actual output scales before freezing typography. Active tasks use a narrow accent rule and a quiet tonal change; ambient metrics stay secondary. Hover and keyboard focus reveal interactivity without making the resting bar busy.

### Colours come from Stylix

The table above records the prototype's own palette. The shell no longer carries those values: `Theme.qml` names the roles it renders and reads the primitives from the machine's base16 scheme, which reaches it as a generated `StylixPalette.qml`. `stylix.targets.quickshell` is what hands the palette over, and the shell keeps a Catppuccin Mocha fallback so that a machine built without Stylix still has a complete theme. Changing the scheme therefore changes the shell without a QML edit.

Under Catppuccin Mocha that maps primary text to base05, secondary text to base04, accent to base0D, attention to base0A, critical to base08, and every glass backing to base00. base03 is deliberately unused: at 3.4:1 against an opaque base00 it is not a readable text colour, and every quiet string in this shell is still meant to be read, so secondary labels, headings and "unavailable" readings share base04 and hierarchy comes from size, weight and spacing.

The alphas did not change with the scheme, and neither did their shortfall. Measured against the brightest region behind each surface on the current wallpaper, the occupied bar leaves primary text at 7.3:1 and secondary text at 4.7:1, while the empty bar leaves them at 4.9:1 and 3.2:1 — primary text clears 4.5:1 on the bars in both states. A popup or banner at 0.40 over the brightest pixel anywhere still leaves primary text at 2.2:1. Denser backings would meet the 4.5:1 target for normal text and hide the wallpaper the material exists to show, so the compromise stands as a deliberate one. These are calculated samples over the wallpaper rather than captures of the composited output, so a live measurement is still owed.

Use restrained personal details already present, such as the small flag and a quiet cat silhouette. Continuous decorative cat animation is not required. The bar may show the NixOS version; the identity popup still holds the fuller machine and system details.

### Composition and limited space

```text
TOP    time · identity     |        media        | health · power · audio · tray | bell
                                      desktop
BOTTOM workspaces         | individual titled windows …                         |
```

The top has three layout zones. Media occupies a bounded center zone and truncates before colliding with status. The right cluster groups related readings with subtle separators: throughput; temperature/memory/pressure/failed units; battery; audio; tray; notifications. Healthy or absent optional signals do not create empty slots.

The bottom is a navigation bar: global workspaces first, then one button per window, including windows on other workspaces/outputs. Task widths adapt within a useful range (prototype: approximately 120–260 px), then overflow into a titled window list, which carries the same order. Preserve workspace identity in that list. Do not silently drop windows or reserve a V2-shaped empty space in V1.

Buttons are ordered by workspace, then by the window's own position on the screen. Workspace 1 precedes workspace 2, and two windows on one workspace read left to right and top to bottom, following their layout. Containers that share a position — the windows of a tabbed or stacked container — keep their first-seen order. Titles and focus never reorder the buttons, but moving or resizing a window does; that replaces the earlier "keep order stable" rule at the user's request.

On narrower outputs, shorten identity/date/media first, then collapse secondary telemetry into its health entry. Preserve window access, workspace switching, battery/awake status, audio, and the bell. Test portrait and mixed-scale displays, not just the wide reference render.

## Behavior contract

### Bars and ordinary popups

- Clock opens a compact calendar; identity opens machine/system details. No agenda or account integration in V1.
- Media opens playback controls. Keep MPRIS player choice stable and handle a player disappearing. Retain the existing playerctld behavior where useful.
- Health opens network, memory, PSI, temperature when configured, and failed system/user service details. Retain a route to the existing full-screen `btop` view. Never turn a failed read into a plausible zero.
- Audio click opens volume/output controls, scroll adjusts by 1%, middle-click toggles mute, and right-click can retain the `pavucontrol` escape hatch. This deliberately changes the current primary-click mute behavior.
- Workspace click and scroll switch predictably without wraparound. Window click activates its workspace/window; middle-click requests close. Avoid optimistic removal before compositor confirmation.
- System tray items retain their native activation/menu behavior. Existing network/Bluetooth tray utilities remain usable; V1 does not need bespoke control panels for everything.
- One interactive popup is open across the shell at a time. It opens on the invoking output, closes on Escape or outside click, and restores focus appropriately. Bars do not take keyboard focus at rest. Repeating an active trigger closes its panel.
- On output removal, close or relocate the panel safely. Shared state does not reset when an output is added or removed. Notification banners appear once, on the output the notification arrived on, with the focused output as the fallback.

### Battery and Keep awake

The Battery popup owns charge/time details, available power profiles, and Keep awake. On a desktop without a battery, expose the same controls through a compact Power entry rather than hiding idle inhibition. Show unavailable/degraded profile states honestly.

The display backlight joins this popup as a slider rather than taking its own bar entry, added after V1: the top bar already carries one reading per device, and brightness is something adjusted rather than watched. The slider and the compositor's brightness keys read and write the same brightnessctl device, the slider is absent on a machine with no backlight, and a change the backlight rejects falls back to the reading the machine reports.

Keep awake offers 30 minutes, 1 hour, and explicitly “Until turned off”; default to a bounded hour. Display the remaining time in the popup and a small persistent indicator in the bar. Explain that it temporarily prevents automatic idle behavior, not that it disables all locking.

Attach the live inhibitor to a long-lived bar surface, not the popup: closing the popup must not end it. Use a deadline that is rechecked after suspend/resume and output changes. Cold shell restart resets inhibition off; do not silently persist “forever.” Verify actual compositor behavior before deciding whether one inhibitor or one per visible output is needed. Quickshell's [IdleInhibitor](https://quickshell.org/docs/v0.3.0/types/Quickshell.Wayland/IdleInhibitor/) is surface-associated, so fullscreen/visibility behavior is an implementation gate.

Preserve the current Swayidle sequence: lock at 300 seconds, DPMS off at 600, suspend-then-hibernate at 1800, and unconditional locking before sleep. Test Keep awake against that exact configuration; manual locking and before-sleep locking must remain effective.

### Notification center

The bell is the last control on the top bar. Unread count and critical attention are distinct from “how many entries are saved.” Merely opening the column is not a notification action; mark entries read when presented, without invoking their actions.

Use a single scrollable history list with compact app/time metadata, title, readable body, and explicit actions. Avoid nested cards. Ordinary completion can wait quietly; critical events get a restrained edge/color and remain accessible. The panel overlays the desktop, reserves no extra workspace, and grows downwards with its content until the list scrolls.

V1 policy:

- Do Not Disturb pauses banners, not history or unread counts. Critical notifications may bypass it; state that exception in the control's explanation.
- Keep a bounded, session-local history of 100 entries; transient notifications are not archived. No notification body or image persistence to disk.
- Respect replacement IDs, explicit client closure, supported timeout semantics, and action invocation. Separate banner visibility from history retention and client liveness: closing a banner is not dismissing the notification.
- Dismiss and Clear all remove local history immediately; V1 does not offer Undo.
- Bound image/body sizes; render untrusted text safely. Advertise only notification capabilities actually implemented. No arbitrary command or remote resource execution from notification content.
- Hot reload and a cold restart are different: do not promise session history survives a process exit. Keep-on-reload behavior needs an explicit test.

Quickshell provides the [notification server](https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.Notifications/NotificationServer/), but lifecycle and history policy remain our responsibility. Its [Notification API](https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.Notifications/Notification/) distinguishes tracking, expiration, and dismissal; archive data separately from live objects.

Safety-critical compatibility: the existing Sway logout binding waits for a critical `notify-send --action=default="Log out" --wait` response. V1 must deliver the chosen action correctly and must not treat timeout/dismissal as confirmation. Test with a harmless stand-in command, never a real logout during automated validation.

## Implementation architecture

Build a small set of modules with real responsibilities. Visual components consume snapshots/models and explicit actions; they do not each discover devices, poll processes, or own protocol state.

| Module | Public surface | Complexity it owns |
| --- | --- | --- |
| Shell session / popup host | Current open panel and output; open/close; focus restoration | One-panel policy, geometry, hotplug and keyboard ownership. |
| Desktop model | Workspaces, windows, focused IDs; activate/switch/close | Sway IPC identity, tree/event reconciliation, floating/Xwayland windows, workspace moves and the workspace-then-position task order. |
| Notifications | History, unread/DND; dismiss/undo/invoke | D-Bus ownership, live versus archived lifecycle, replacement, timeouts, safe content. |
| Health | Metric snapshot and failure/availability flags | Shared sampling, counter resets, hwmon paths, PSI and failed-unit queries. |
| Power, audio, media, tray | Their native state and narrow user actions | Service disappearance, device/player identity and operation errors. Keep these separate where their lifecycles differ. |
| Per-output views | Render shared state and route interactions | Layout and presentation only; no duplicate polling or notification servers. |

Start with native Quickshell service modules for UPower/power profiles, PipeWire, MPRIS, and StatusNotifier items, checking the pinned package's actual APIs. Use explicit adapters only for real gaps such as Sway window enumeration and `/proc` health metrics. No generic plugin bus or speculative backend framework.

[Quickshell.I3](https://quickshell.org/docs/v0.3.0/types/Quickshell.I3/I3/) supplies workspace/compositor integration, but do not assume it supplies a complete window-task model. Plan a Sway tree/event adapter keyed by container ID, including title/focus/move/close events, floating windows, scratchpad policy, and reconnect reconciliation. Keep commands structured and never interpolate window titles into shell code.

Proposed source placement:

```text
modules/apps/quickshell.nix       feature, package/config generation, session wiring
modules/apps/quickshell/
  shell.qml                      shared models and per-screen instantiation
  Bar.qml                        top/bottom bar composition
  PopupHost.qml                  shared panel policy and placement
  Theme.qml                      tokens and common glass material
  desktop/                       Sway model and workspace/task views
  notifications/                 server/history and presentation
  status/                        health, power, audio, media and their popups
```

This is an ownership map, not a requirement to create empty scaffolding. Add components only when they hide meaningful complexity. Keep source assets next to the feature; expose declarative runtime values through generated configuration, including sensor paths and absolute executable paths. Preserve the established repository module pattern rather than introducing project-level enable options or new flake inputs.

### Glass is compositor work

The repository already uses SwayFX and enables blur. Real layer surfaces need explicit, stable Quickshell namespaces and corresponding SwayFX layer effects. [PanelWindow](https://quickshell.org/docs/v0.3.0/types/Quickshell/PanelWindow/) provides anchored exclusive bars; [WlrLayershell](https://quickshell.org/docs/v0.3.0/types/Quickshell.Wayland/WlrLayershell/) provides namespace and focus settings. Configure namespaces before mapping the windows.

Use the compositor's [layer effects](https://github.com/WillPower3309/swayfx#layer-shell-effects) for live blur. Verify both bars and popup/notification surfaces; do not assume a Qt popup gets the same treatment automatically. If necessary, use a dedicated layer surface for the notification panel instead of a popup type that cannot obtain the required material/focus behavior.

The HTML contains a viewport-aligned blurred wallpaper fallback because the headless renderer did not paint `backdrop-filter`. That is a screenshot workaround, **not** a live-shell technique. Do not duplicate the wallpaper behind panels: real windows must blur correctly too. Keep the chosen 40% backing and calibrate blur/contrast on bright sky and busy application backgrounds. Do not apply opacity to the whole window, including text. V1 does not offer an opaque or reduced-transparency fallback.

## Migration from the current configuration

The baseline was the Waybar feature, with session and notification ownership in [sway.nix](../../modules/apps/sway.nix).

| Touchpoint | Planned change / invariant |
| --- | --- |
| `modules/apps/quickshell.nix` | Export the native NixOS/Home Manager feature modules; use packaged Quickshell and generated configuration. Home Manager exposes `programs.quickshell` configuration and systemd integration; verify the pinned version's exact options before implementation. |
| `modules/apps/waybar.nix` | Retired after cutover, together with the two Waybar-oriented packages that only served it; the `hardware.sensors.cpuTemperature` declaration moved to the replacement feature without changing its path. Rollback is the commit that drops them. |
| `modules/apps/sway.nix` | Add layer effects; transfer service conditions to Quickshell; remove Mako ownership only at notification-server cutover. Keep SwayFX, UWSM, `bars = []`, lock/idle policy, launcher, and unrelated utilities. |
| `modules/roles/workstation.nix` | Replace the Waybar aspect with Quickshell. Do not change unrelated roles or the base-role invariant. |
| `modules/machines/stylix-test.nix` | Replace its direct Waybar import too. This is an important V1-without-herdr test machine. |

Do not simultaneously compose two features declaring the same sensor option. During development, run standalone fixture views rather than importing both full features. Transfer the declaration and all feature imports together at the cutover checkpoint.

Retain systemd service conditions for `WAYLAND_DISPLAY` and `XDG_SESSION_DESKTOP=sway`. Sway is UWSM-managed and its Home Manager `systemd.enable` is currently false; inspect the generated Quickshell unit and use the existing graphical-session lifecycle rather than assuming `sway-session.target` owns it. Stop cleanly on session exit and bound restart behavior after repeated failures.

There must be exactly one owner of `org.freedesktop.Notifications`: Mako before cutover, Quickshell afterward. A preview must not compete with the live daemon. Likewise, two exclusive bar pairs must not reserve desktop space at once.

Preserve useful behavior that is easy to miss in the visual mockup:

- Failed system **and** user unit count, hidden when healthy.
- Memory PSI `some avg60`, hidden at zero, warning at 5% and critical at 20%; details include `some`/`full` 10/60/300 values, swap and zswap.
- Optional configured CPU sensor, 3-second shared telemetry sampling as a starting point, counter-reset and unavailable states.
- Full NixOS version in details, all-output task/workspace access, native tray menus, audio and media behavior.

Backlight, CPU, and Bluetooth definitions that were not mounted in the old bar are not automatic parity obligations. A redesign may relocate details, but it must not quietly discard health warnings.

## Ordered implementation plan

1. **Compatibility and fixture shell.** Confirm the repository's packaged Quickshell version against the 0.3.0 API baseline used here. Inspect Home Manager's pinned integration. Create fixture-driven QML views with no production notification ownership or compositor mutations. Evaluate the planned module composition, including sensor-option ownership.
2. **Bars and material.** Implement per-output geometry, exclusive zones, typography/tokens, real SwayFX blur and the single popup host. Validate sky and working-window backgrounds, scales, hotplug and keyboard focus before adding all content.
3. **Navigation and everyday status.** Implement and test the shared desktop model, task overflow, calendar/identity, media, tray and health. Verify current warning thresholds and missing-device behavior.
4. **Power and audio.** Add Battery/Power with profile availability and Keep awake deadlines; verify lock/DPMS/sleep interactions. Add audio controls and error feedback without pretending an unsuccessful change took effect.
5. **Notifications.** Test the server in an isolated session first, including actions, replacement, DND, expiry, bounded history and client closure. Reproduce the logout notification using a safe test action.
6. **Nix cutover and acceptance.** Switch imports and session ownership atomically; remove competing Waybar/Mako startup. Format changed Nix, stage new source files, evaluate affected configurations and run applicable flake checks. Inspect/build generated artifacts before any user-authorized activation.

Each checkpoint should leave a testable result. Do not wait until a full shell exists to discover that popup blur, notification actions, or idle inhibition do not work.

### Release gate and rollback

- Exercise two outputs, output unplug/replug, fractional scaling, portrait geometry, many windows, long/CJK titles, fullscreen, scratchpad and compositor reconnect. Confirm task order follows workspace and on-screen position when windows are moved, resized, stacked or tabbed, and that the overflow list matches the bar.
- Verify only one poller per metric and one notification server regardless of output count. Measure idle CPU, wakeups, and memory against the current Waybar/Mako baseline under the same conditions; investigate sustained regressions rather than inventing a target from the HTML.
- Validate malicious/oversized notification input, stale actions, transient/replaced/critical notifications, clear, DND and process restart.
- Verify Keep awake survives popup closure, expires correctly after resume, and does not bypass explicit lock/before-sleep protection.
- Keep pure model/lifecycle tests separate from QML interaction tests and a real SwayFX integration checklist. Nix validation must preserve `nixos-configurations-import-base`; no blanket dependency update is part of this work.
- Test first in the existing VM/test configuration where practical, then on a real output with explicit activation approval. A VM may not establish final blur/performance quality.
- Rollback restores the previous Waybar aspect, its sensor-option owner and service conditions, and Mako as the sole notification daemon, or uses the previous working NixOS generation. Keep that complete path available until normal daily use is verified. Do not deploy or alter the running session merely to prepare these plans.

V1 is done when the everyday desktop works independently of herdr, the chosen visual system survives real application backgrounds and output changes, and notification/power behavior is safe. V2 must extend that foundation without becoming a prerequisite for it.
