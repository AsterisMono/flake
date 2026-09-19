# 0002 — V2: Work in flight and herdr

Status: steps 1–4 implemented and exercised against the live socket; the opt-in trial, window targeting and the remaining acceptance sweep are open. See [Implementation record](#implementation-record).

Recorded: 2026-09-18.

Prerequisite: [0001 — V1: the everyday shell](0001-v1-core-shell.md).

## Intent

Give ongoing agent work a quiet place in the desktop: visible enough to return to, unobtrusive enough to leave alone. **Work in flight** is a compact summary at the right of the bottom bar, opening a column of work that is running, needs the user's input, or is ready to revisit.

The user's selected direction is to connect this to **herdr**. Herdr remains the authority for sessions, agents, and their detected state; Quickshell becomes a small, caring view onto that work. It does not become another agent orchestrator.

“You can leave these here. Finished work will wait.” is the design attitude. Actual state labels must remain more precise: an agent reporting `done` means ready to review, not proof that its task or checks succeeded.

## Archived exploration

[Open the interactive prototype](quickshell.prototype.html) and choose “Work in flight”; the URL query `?preview=work&glass=C` also selects this view. [V1's document](0001-v1-core-shell.md#archived-design) describes the shared material.

The exploration was reviewed as a rendered HTML capture at 1920 × 1080 logical pixels, not live herdr data; the capture is not kept in the repository. Prototype controls were hidden for it. The build/download/check rows, percentages, Stop and Retry actions are illustrative interaction samples. They are **not** an assertion that herdr supplies progress, build results, safe cancellation, or restart operations. Return thread bookmark controls remain visible in this archived exploration; that feature is not selected for V2.

Carry forward the panel's feeling, grouping, restraint, and persistence of ready work. Replace its invented job semantics with the verified herdr model below.

## Scope

V2 adds:

- A shared herdr connection and normalized activity model.
- A bottom-right summary of working / idle / waiting-on-you counts. Blocked agents and agents herdr reports `done` share one “needs you” chip; a quiet session shows `N idle`, or `no agents` when herdr is up with none attached.
- A frosted panel using V1's material, popup policy, keyboard behavior, output placement and reduced-motion treatment.
- Explicit navigation back to the relevant agent; optional bounded recent-output inspection initiated by the user.
- Honest unavailable/stale states and reconciliation after reconnect.

V2 initially does **not** add generic process tracking, download/build hooks, automatic agent creation, prompt submission, approval of agent permissions, terminal input injection, Stop/Retry, cross-host discovery, a new notification daemon, or persistent transcript storage. Return thread remains outside the selected release.

## Interaction design

Keep the bottom bar primarily for windows. Work in flight is one compact end section, not one widget per agent. Counts update without making task buttons continually reflow: reserve a modest summary width while visible and use a compact form on narrow outputs. With no relevant work, remove the section; do not keep an empty dashboard on the desktop.

The panel starts around 400 logical px wide, aligns with the triggering bottom-right section, and grows upward within the output. It is a list with separators, not stacked rounded cards. Use the same 40% backing opacity as V1; text remains opaque.

| Group | Meaning and presentation |
| --- | --- |
| Needs you | Herdr reports blocked. Explain that input may be needed; do not invent the question or label it a failure. Small amber emphasis, explicit Open agent action. |
| Ready when you are | Herdr reports done, right now. The row is the live state and leaves the panel as soon as herdr reports something else; no claim of successful tests or deployment. Quiet blue-grey emphasis. |
| In progress | Herdr reports working. Show agent/project identity and trustworthy context, not a fabricated percentage or animated activity spectacle. |

Order groups by attention, then keep item order stable within them. Idle/unknown agents do not count as working or ready. An optional compact “Other agents” disclosure can make them inspectable without filling the primary panel.

Each row should answer: which agent, in which project/workspace, what herdr currently knows, and where to return. Prefer a meaningful user-provided name/title; fall back to agent type plus workspace. Treat state labels as supplementary text, not a second source of truth. Use a compact path and relative last-change time only when their meaning is known. A locally observed timestamp must not masquerade as the true job start time.

Actions:

- **Open agent** explicitly focuses the target in herdr and raises its owning desktop window only when that mapping is reliable. Opening the panel never changes the user's active workspace.
- **Recent output**, if implemented, fetches a bounded text snapshot on demand. It is not a live transcript stream and is not automatically copied into notifications or logs.
- **Dismiss** is not part of V2: the panel holds no local record to acknowledge. Nothing the shell does closes a pane, stops an agent, changes its herdr state, or marks work successful.
- A target that no longer exists leaves the panel with its pane. The shell keeps no context for it, and closure is not inferred as successful completion.

**The panel is herdr's state, not a log of it (2026-09-19).** V2 first kept a local readiness record for every `done` transition, so a completion stayed visible until the user acknowledged it from the panel. In practice such a record asked for attention only while herdr still called that agent done — the user handles the work in herdr, and herdr's own `done` state stays put until the agent moves on — so the record could outlive the request it stood for and leave the chip standing after the user had already dealt with it in herdr. The shell therefore keeps no history at all: rows and counts are derived from the current agent list, a completion leaves the panel the moment herdr reports something else or its pane disappears, and the shell never remembers a completion herdr has stopped reporting. Nothing is persisted, and there is no dismissal to undo.

Loss of connection changes the source to “Disconnected — last seen …”, not “Failed.” The last snapshot's rows stay visible and marked stale instead of being emptied, and the panel says how old they are; if herdr has never been configured or available, V1 stays quiet without an error badge. Opening/reconnecting to the panel does not trigger a burst of completion notifications.

## Verified integration baseline

### Verified during implementation (2026-09-18)

Read-only probes of the running socket (`herdr 0.9.1`, protocol 22) and the bundled schema established the wire behavior the adapter is built on:

- The server **answers one request per connection and then closes it**. A second request on the same connection fails with a broken pipe. Every ordinary request therefore opens its own short-lived connection.
- `events.subscribe` returns `{"type":"subscription_started"}` and keeps the connection open for `{"event": …, "data": …}` envelopes. That connection also accepts **exactly one** request: a second `events.subscribe` on it resets the connection. Changing the subscription set — which is required when a pane starts hosting an agent, because `pane.agent_status_changed` needs a `pane_id` — means opening a fresh subscription, then reconciling.
- Requests are newline-delimited `{id, method, params}`; replies are `{id, result}` or `{id, error:{code,message}}`. A read-only probe of a nonexistent target returned `agent_not_found`, and `agent.read` returned a bounded `pane_read` result.
- Snapshot agents carry `pane_id`, `terminal_id`, `workspace_id`, `tab_id`, `agent`, `agent_status`, `revision`, `state_change_seq`, `cwd`/`foreground_cwd` and the terminal title; `agent_session` was absent in the observed session, so identity falls back to endpoint + terminal + pane and treats a missing session reference conservatively.
- **Pane → desktop-window targeting is not derivable from the API.** Herdr panes are children of the herdr server, not of the terminal emulator window, and the API exposes no client list. The only honest per-session relation is process ancestry (herdr client → terminal emulator → Sway window), which says nothing about *which* window should be raised when several clients are attached. Per the navigation rules above, the shell therefore only asks herdr to focus, and says so instead of moving a guessed workspace.

Repository and local inspection on 2026-09-18 found:

- [herdr.nix](../../modules/apps/herdr.nix) already manages the package, TOML configuration, and declared plugin links.
- [agents.nix](../../modules/apps/agents.nix) composes herdr, enables the existing reviewr integration, and selects system toast delivery. Keep that workflow intact.
- A Waybar-oriented summary tool, `wayherdr`, packaged the same data for the old bar. The Waybar module never mounted it, and it was dropped with the rest of the Waybar feature; formatted Waybar output is not the basis for the new data model.
- The installed CLI reported **herdr 0.9.1**. Its bundled `herdr api schema --json` reported **protocol 22**, schema version 1. These are observed compatibility facts, not permission to pin or update dependencies in this change.

The bundled schema was inspected without reading live agent contents or contacting an active session. Recheck the package selected by the repository at implementation time; an installed binary and the evaluated flake package may differ.

Herdr's [socket API](https://herdr.dev/docs/socket-api/) is a local Unix-socket, newline-delimited JSON protocol with request IDs and event subscriptions. Prefer that structured source for a long-lived integration. Its [agent model](https://herdr.dev/docs/agents/) owns state detection; Quickshell must not independently infer status from terminal prose or window-title changes.

Observed API surface relevant here:

- `session.snapshot`, `agent.list`, `agent.get` for state and reconciliation.
- `events.subscribe` for changes; subscriptions include pane/workspace lifecycle events and per-pane `pane.agent_status_changed`.
- `agent.focus` for an explicit user navigation request.
- `agent.read` / pane output APIs for a separately validated, bounded read action.

The inspected schema does **not** expose a semantic `agent.cancel` or `agent.retry`, nor an agent progress percentage or generic failed status. Do not substitute `server.stop`, pane closure, or injected Ctrl-C for a safe cancellation contract.

## State model

Keep source state and connection freshness separate. A lost socket is not an agent failure, and the panel is a view of herdr's state rather than a second opinion about it.

| Herdr `AgentStatus` | Shell interpretation | Avoid |
| --- | --- | --- |
| `working` | Working; counted in progress | Fake percentages, predicted remaining time, inferred task success. |
| `blocked` | Needs you; counted separately | Calling every blocked state an error or automatically approving anything. |
| `done` | Ready to review, while herdr keeps saying so | “All checks passed” without a separate trustworthy result source. |
| `idle` | Idle; available through optional detail | Treating idle as done or failed. |
| `unknown` | State unavailable | Guessing state from agent title or decorative labels. |

Suggested normalized activity:

```text
Activity
  identity: endpoint/session identity + terminal identity + agent-session identity when present
  target: current workspace/tab/pane identifiers for routing
  sourceState: working | blocked | done | idle | unknown
  freshness: current | stale | unavailable
  display: agent, title, workspace, project path, safe supplementary labels
  sourceRevision, sourceStateChangeSeq, connectionEpoch
  observedAt, lastStateChangeObservedAt
```

`AgentInfo` contains `terminal_id`, workspace/tab/pane IDs, `revision`, and `state_change_seq`; `agent_session` is optional. Pane IDs alone are insufficient identity across sessions/restarts. Treat an absent or changed agent-session identity conservatively: never aim an action at a replacement agent merely because its title or pane slot matches.

Resource revisions and state-change sequences are not a global event clock. Namespace them by source/resource and reset assumptions when the source session is replaced. Use a local connection epoch to discard responses from old connections. The shell derives no record of its own, so identity only has to keep an action pointed at the pane it was aimed at while that pane is still the one herdr reported.

The inspected status event carries state and identifiers but no universal sequence/revision. Treat events as invalidations, then fetch authoritative agent/snapshot data. A live view can only be as good as its source: do not let an unversioned event overwrite a newer snapshot just because it arrived last, and if a transition is missed during a disconnect, show the reconciled state without inventing its duration or outcome.

## Implementation seams

| Module | Small public interface | Hidden responsibility |
| --- | --- | --- |
| WorkInFlight model | Items/groups/counts, source health; open | A live projection of the source: presentation rows, freshness and stable ordering. No local history, acknowledgement or persistence. |
| WorkSummary | Bar chips and whether the section is visible | Compact vs full wording for the same counts. |
| WorkRaise | Raise the hosting terminal when mapping is exact | Process ancestry vs Sway window pids. Silent no-op when the mapping is not exactly one window. |
| Herdr adapter | Snapshot/change stream and explicit focus/read operations | Socket lifecycle, framing, request correlation, subscriptions, schema compatibility, identity and reconciliation. |
| Fixture adapter | The same data/action boundary, deterministic simulated responses | Offline UI work and tests for blocked/done/disconnect/restart cases without touching real agents. |
| Work panel and bar entry | Render models; invoke the above actions | Layout, keyboard access and interaction feedback only. |

Use an adapter because there is a real external protocol and a real test fixture, not to build a general backend framework. Reuse V1's single popup host; keep one shared herdr model for all outputs. No duplicate socket subscribers or state stores per bar.

Preferred source home is `modules/apps/quickshell/work/`, with integration values wired by `modules/apps/quickshell.nix` alongside the existing herdr configuration. V1's source may include the optional view without requiring herdr to be enabled. Do not make importing the core shell start herdr. Avoid a new flake input unless the pinned package demonstrably cannot satisfy the design.

First evaluate a direct Quickshell Unix-socket adapter. If protocol handling genuinely needs a helper for bounded framing, testing, or compatibility, make that a small feature-owned package under `modules/packages/`; decide from the spike, not by scaffolding a daemon prematurely. Never shell out to a poll loop for every row.

### Connection and reconciliation sequence

1. Resolve an explicitly configured local endpoint/session. Respect herdr's configuration/socket overrides; do not assume every graphical session should attach to one hard-coded default path. Initial rollout can support one endpoint, while namespacing identities correctly. Do not scan remote machines or auto-launch sessions.
2. Connect with request deadlines and bounded frame sizes; inspect protocol/version and supported operations. Unsupported protocol gets a recoverable source-unavailable state, not best-effort mutating calls.
3. Subscribe to pane/workspace lifecycle invalidations and obtain a snapshot. Establish the required per-pane status subscriptions, then reconcile again to close the snapshot/subscription race. Do not assume a global wildcard status subscription: the inspected `pane.agent_status_changed` subscription requires a `pane_id`.
4. Coalesce invalidations into targeted `agent.get` requests or a snapshot refresh. Update subscriptions when panes appear/disappear; match responses by ID. Handle split/multiple JSON lines, malformed input, closed targets and responses arriving out of order.
5. On connection loss, mark state stale immediately, bound retries with backoff, and reconnect with a fresh authoritative snapshot. A low-frequency shared reconciliation can cover missed events; it is not a substitute for correct subscription ownership.
6. On shell shutdown, close the subscriber without stopping the herdr session. On output hotplug, change only the views.

Verify exact request/event envelopes against the bundled schema: subscription names such as `pane.agent_status_changed` and delivered event kinds such as `pane_agent_status_changed` are not interchangeable strings.

### Navigation and privacy

`agent.focus` addresses herdr's pane selection; it does not by itself prove which Sway window should be raised. Establish a reliable relation to the owning terminal window using verified process/session metadata. Never focus a guessed window based on its display title. If that relation cannot be established, leave the desktop alone: do not move a guessed workspace and do not add extra panel copy for the miss.

Keep the initial action allowlist narrow: read state, user-requested bounded recent output, and explicit focus. Use pane/terminal identity with a freshness check before acting. Surface disappearance or permission errors instead of silently retrying a command against a reused pane ID.

No automatic prompt capture, full transcript ingestion, secret-bearing API debug dumps, or transcript persistence. Render output as plain text, stripping terminal control sequences and bounding bytes/lines. Do not interpret agent output as shell commands, markup, or permission to act. Freeze fixture data in tests rather than recording real sessions.

The existing reviewr workflow stays in herdr. A future direct “Review” shortcut needs verified plugin capabilities and target semantics; the prototype's “Review result” label is not enough to invent that integration.

## Relationship to notifications

Herdr already delivers system toasts. V1 receives those through its notification server; V2 should not emit a second toast for every observed herdr transition. The bar and Work in flight panel show live agent state while ordinary notifications retain their own lifecycle.

Do not deduplicate by guessing from notification titles. If tighter linking is later useful, require an explicit shared identifier/capability. The V2 panel and notification center obey the same one-open-panel rule.

**Do Not Disturb pauses banners, and nothing else (2026-09-19).** `Notices.dnd` governs:

- new banners: a notification that arrives while DND is on is kept in the panel and shown there, without a banner. A critical notification still gets its banner;
- the bell glyph (`bell` / `bellOff`) in the panel's title row, which is the only indication while it is on; the panel carries no explanatory line.

It does **not** touch unread counts, critical emphasis, history retention, live-versus-archived state, or Work in flight state. An agent that needs input still says so while DND is on, and clearing the unread badge would hide the one durable signal the panel has.

Banners and history are two halves of one record: a banner is the transient view of a notification that also lives in the panel, closing a banner is not dismissing the notification, and a transient notification gets a banner with an explicit “not saved to history” note instead of a history entry. Undo is deliberately absent from both halves.

## Ordered implementation plan

1. **Protocol and targeting spike.** Recheck installed/evaluated package versions and the bundled schema. In a disposable, explicitly created test session, verify snapshot identities, per-pane subscriptions, agent state transitions, restart behavior, focus semantics and bounded output reads. Do not experiment on the user's active agents.
2. **Fixture-backed model and view.** Implement the normalized states, compact counts, stable groups, readiness retention, dismiss/Undo and disconnected UI. Replace prototype job percentages with meaningful agent state. Verify the V1 shell remains complete with the feature absent.
3. **Read-only live adapter.** Implement framing, snapshots, dynamic subscriptions, reconciliation and reconnect. Exercise it against the disposable session. No focus, output capture or process-control side effects merely from opening the panel.
4. **Explicit return-to-work actions.** Add focus only after target identity/window mapping is validated. Add bounded recent output if it improves the workflow without duplicating the terminal. Keep Stop/Retry absent until a separate semantic contract is justified.
5. **Opt-in real-session trial.** Wire a chosen local endpoint, measure overhead and state quality during ordinary herdr use, and verify toast behavior. Ship with a reversible configuration change; disabling the connection must leave V1 intact and herdr running normally.

### Acceptance cases

- Working → blocked → working → done has correct labels/counts. Idle and unknown never produce false completion. Agent-detected states are shown as herdr's report, not proof of task success.
- A `done` agent appears under Ready when you are and holds the chip while herdr keeps reporting it; the row and the chip clear as soon as herdr reports any other state for that agent, or its pane is gone. Nothing the shell remembers can resurrect a completion herdr has stopped reporting.
- Source disconnect/restart, missed events, malformed/partial frames, stale replies, version mismatch and absent socket produce bounded resource use and honest availability.
- Pane closure/reuse, optional agent-session identity, identical titles and multiple endpoint namespaces cannot route an action to the wrong agent. Retry/focus after source replacement must revalidate identity.
- Adding/removing outputs does not duplicate subscriptions, counts, actions or notifications. Opening a panel never focuses an agent; only the explicit action does.
- Large output, ANSI escapes, markup-like text, CJK titles, missing project paths, many agents and long names remain safe and usable.
- No herdr session is started, stopped or modified by shell startup/shutdown. No prompts or permission responses are injected. No real transcripts are written to test fixtures or logs.
- System toast delivery remains unchanged and is not duplicated. DND does not suppress the activity model. V1 remains functional on a machine without herdr.

## Gates before broadening V2

The remaining engineering questions are concrete: reliable desktop-window targeting, state quality for each supported agent, identity across restored sessions, and the pinned protocol's subscription/lifecycle behavior. Resolve those in the spike rather than obscuring them with optimistic UI.

Generic build/download progress, safe cancellation/retry, durable cross-login history, remote sessions, and richer reviewr actions can follow if real use calls for them and their sources expose trustworthy contracts. They are not hidden prerequisites for delivering the selected Work in flight experience.

## Implementation record

Landed in V2, under [modules/apps/quickshell/](../../modules/apps/quickshell/):

| Piece | File | Notes |
| --- | --- | --- |
| Herdr adapter | `work/HerdrClient.qml` | One connection per request, one long-lived subscription, pane-set-driven re-subscription, reconnect backoff, incompatible-protocol state, sanitized bounded reads. Read-only apart from the explicit `agent.focus` action. |
| Fixture adapter | `work/FixtureSource.qml` | Same data and action boundary, deterministic scenarios selected with `QS_WORK_FIXTURE=flights\|followup\|disconnected\|ended\|empty\|incompatible`. Every string is sample data. |
| Work in flight model | `work/WorkInFlight.qml` | Live projection of the source agent list: normalized rows and groups, stable ordering by attention, honest source line. No retained records, acknowledgement or history. Opening a row focuses that agent and keeps the rows herdr's. |
| Bar summary | `work/WorkSummary.qml` | One compact end section: working / idle / waiting-on-you chips. Blocked plus ready share “needs you”. Quiet herdr is `N idle`, or `no agents` when the session has none. |
| Host raise | `work/WorkRaise.qml` | After `agent.focus`, raise the hosting terminal only when process ancestry matches exactly one Sway window; otherwise leave the desktop alone. |
| Panel | `popups/WorkPopup.qml`, `components/AgentRow.qml` | Prototype structure: header with description, group titles with counts, list rows with separators, quiet footer. Every agent herdr knows appears, grouped by attention (`Needs you`, `Ready when you are`, `In progress`, `Idle`), each as one plain line: title, status, context, and an honest note where the state needs one. A row is the control — clicking it opens that agent and nothing else. No action buttons and no collapsed sections, at the user's request. |
| Bar entry | `BottomBar.qml` | Renders `WorkSummary`; the section is present while herdr is reachable. |
| Return to work | `work/WorkInFlight.qml`, `work/WorkRaise.qml`, `Desktop.qml`, `default.nix` | `agent.focus`, then the hosting terminal window is raised **only** when the herdr client's process ancestry matches exactly one Sway window. |
| Wiring | `ShellState.qml`, `PopupHost.qml`, `default.nix` | Bottom-anchored popup at 400 logical px, `Runtime.herdrEndpoint` and `Runtime.herdrHostScript` derived from `programs.herdr.enable` and `$XDG_CONFIG_HOME`. |

Endpoint: the shell connects only to the socket path derived from the machine's herdr configuration (`$XDG_CONFIG_HOME/herdr/herdr.sock`) and stays quiet when herdr is not part of the machine. Named herdr sessions and remote machines are out of scope for this round.

Verified in the headless review instance (`/tmp/qs-work/review.sh`): fixture mixes, disconnected presentation, hidden section when herdr is absent, and a live run against the running socket — snapshot, workspace labels, and a bounded `agent.read` all returned correctly without touching the session. The live projection was confirmed on 2026-09-19 with the `followup` fixture (a `done` agent the user handled in herdr leaves both the Ready group and the chip as soon as the source reports it working) and the `ended` fixture (a pane that disappears takes its row with it).

Frame and failure modes were exercised against an adversarial stand-in socket (`/tmp/qs-work/fake-herdr.py`), one mode per run:

| Mode | Expected | Observed |
| --- | --- | --- |
| valid snapshot | online, counts and one ready record | `1 needs you · 1 working · 1 ready`, ready record retained |
| garbage line before a valid reply | frame skipped, reply still applied | online with the same counts |
| reply split across writes | reassembled | online with the same counts |
| oversized frame | bounded failure, honest source line | "Connected to herdr, but herdr sent an oversized frame." |
| connection closed with no reply | disconnected, quiet | `disconnected`, section hidden |
| reply later than the request deadline | timeout reported, no hang | "Connected to herdr, but herdr did not answer in time." |
| working → blocked → working → done | labels and counts follow, `done` keeps a record | `working` → `needs you` → `working` → `ready to review` (record retained) |
| source restart (socket gone for six seconds) | stale, then reconcile | `disconnected` with counts and the ready record kept, bounded retries, `online` again on the fresh subscription |

These runs observed the readiness records the shell no longer keeps, so "ready record retained" describes that round rather than today's model; the live projection is the 2026-09-19 behaviour noted above.

Two implementation findings came out of that sweep and are fixed in `HerdrClient.qml`:

- A `QLocalSocket` that has been closed or has errored cannot be revived by setting `connected` back to true, and a silent failure there left the panel claiming a connection it did not have. The subscription now owns a **fresh socket object per attempt**, with the client ignoring events from any socket that is no longer current.
- An error reported by an abandoned attempt could arrive after a newer attempt had already connected, which produced a false "Disconnected". Errors and state changes are now ignored unless they belong to the current socket, and a handshake watchdog cycles the connection if a connected socket never acknowledges the subscription.

### Material needs the compositor side

The 40% backing only reads as glass when SwayFX blurs the layer surface behind it. That comes from the `layer_effects` rules for `quickshell-bar-top`, `quickshell-bar-bottom`, `quickshell-popup` and `quickshell-banner` in [sway.nix](../../modules/apps/sway.nix), and the shell cannot supply it itself: without those rules the bars, panel and banners look plainly transparent, which is exactly how a session reads if the running generation predates the rules. A running compositor picks them up from its configuration or from `swaymsg 'layer_effects "<namespace>" blur enable'`; persisting them means activating a generation that contains them.

Popups keep the prototype's `Theme.glass` (`#20212b`, 0.40) over a blurred window. Measuring a headless capture over an unscaled wallpaper confirmed that both bars composite at the same 0.40 when the same backing colour is used, so the visible difference was never opacity: the bars sit on the bare wallpaper, which on this desktop is far brighter than the windows behind a popup, and the same 0.40 there reads as plain transparency. Two changes make the bars read like the panels:

- `Theme.barGlass(occupied)` — one backing used by both bars only: 0.68 while the workspace holds a window, and the popups' 0.40 while it holds none, so a bright or light wallpaper no longer dominates a bar with content to sit next to and an empty workspace keeps the prototype's open look. Text stays fully opaque either way.
- `blur_xray` on the two bar namespaces, which blurs the wallpaper itself — safe for the bars specifically, because tiled windows stop at the bars' exclusive zone and nothing else is ever behind them. Panels keep window blur, because that is what is behind them.

The bar section follows the herdr server rather than the shell: it is present while a session is reachable (counts while work is in flight, `N idle` while it is quiet, `no agents` when the session has none) and gone when herdr is not running. This supersedes the earlier "remove the section when nothing is in flight" rule, at the user's request, and keeps one stable place to look for agent status.

Still open:

- Live trial measurement: overhead during ordinary use, and confirming that herdr's own system toasts still arrive once, unchanged.
- A herdr client that is not inside a window this shell can see (ssh, detached server, a multiplexer) is left on the desktop; that miss stays silent.
- Repeated herdr state quality per agent kind (how often `done` is really ready, how `blocked` reads in practice) is a user-observation item, not a code item.

Not surfaced in V2, deliberately: bounded recent-output reads (the adapter's `agent.read` action was removed with the button that used it), any dismissal or Undo affordance (there is no local record left to dismiss), and Stop/Retry. The state model above still describes what a later round would need if any of them comes back.
