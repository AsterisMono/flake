pragma Singleton
import QtQuick
import Quickshell
import qs

// Deterministic stand-in for the herdr adapter. It exposes the same data and
// action boundary as HerdrClient, so the Work in flight model and panel can be
// exercised — and screenshotted — without touching a live session.
//
// Selected with QS_WORK_FIXTURE=flights|disconnected|ended|empty|incompatible.
// Every string here is sample data; nothing is read from or sent to herdr.
Singleton {
  id: fixture

  readonly property string scenario: Quickshell.env("QS_WORK_FIXTURE") || ""
  readonly property bool enabled: scenario !== ""

  property string state: "online"
  property string serviceVersion: "0.9.1"
  property int protocol: 22
  property string detail: ""
  property double lastSeenMs: 0
  property double lastSnapshotMs: 0
  property bool hasSnapshot: false
  property int updateSeq: 0
  property var agents: []
  property var workspaces: ({})
  property string lastError: ""
  property int focusSeq: 0
  property int cursor: 0

  readonly property string serviceLabel: "herdr " + serviceVersion

  signal focusResult(string paneId, bool ok, string message)

  readonly property double baseMs: Date.now() - 6 * 60 * 1000
  readonly property var workspaceLabels: ({
    "w6": { "label": "waycat", "number": 6, "focused": false },
    "w8": { "label": "flake", "number": 8, "focused": true },
    "w9": { "label": "nori-platform", "number": 9, "focused": false }
  })

  function agent(paneId, terminalId, workspaceId, tabId, name, title, cwd, state, seq, offsetMs, focused) {
    return {
      "paneId": paneId,
      "terminalId": terminalId,
      "workspaceId": workspaceId,
      "tabId": tabId,
      "sessionKey": "sample:" + paneId,
      "agentName": name,
      "displayName": name,
      "title": title,
      "cwd": cwd,
      "focused": focused === true,
      "state": state,
      "stateChangeSeq": seq,
      "revision": seq + 7,
      "observedAtMs": fixture.baseMs + offsetMs
    };
  }

  readonly property var flights: [
    fixture.agent("w9:p2", "term_sample_blocked", "w9", "w9:t1", "claude", "Waiting for approval before running the migration", "/home/nvirellia/Projects/nori-platform", "blocked", 41, 12000, false),
    fixture.agent("w9:p5", "term_sample_ready", "w9", "w9:t2", "codex", "Review the tenant migration diff", "/home/nvirellia/Projects/nori-platform", "done", 88, 45000, false),
    fixture.agent("w8:p6", "term_sample_working", "w8", "w8:t2", "codex", "Implement docs/quickshell v2 | flake", "/home/nvirellia/Projects/flake", "working", 199, 6000, true),
    fixture.agent("w8:p1", "term_sample_idle", "w8", "w8:t1", "opencode", "NixOS build fails on shellcheck SC215…", "/home/nvirellia/Projects/flake", "idle", 23, 90000, false),
    fixture.agent("w6:p1", "term_sample_unknown", "w6", "w6:t1", "cursor-agent", "", "/home/nvirellia/Projects/waybar-toys", "unknown", 4, 120000, false)
  ]

  function snapshotsFor(scenario) {
    switch (scenario) {
    case "disconnected":
      return [fixture.flights];
    case "ended":
      return [
        fixture.flights,
        [fixture.flights[2]]
      ];
    case "empty":
      return [[]];
    case "idle":
      return [[fixture.flights[3], fixture.flights[4]]];
    case "incompatible":
      return [[]];
    default:
      return [fixture.flights];
    }
  }

  function start() {
    fixture.refresh();
  }

  function stop() {
  }

  function retry() {
    fixture.state = "online";
    fixture.lastSeenMs = Date.now();
    fixture.updateSeq = fixture.updateSeq + 1;
    fixture.refresh();
  }

  function refresh() {
    const snapshots = fixture.snapshotsFor(fixture.scenario);
    const agents = snapshots[Math.min(fixture.cursor, snapshots.length - 1)];
    fixture.cursor = fixture.cursor + 1;

    if (fixture.scenario === "incompatible") {
      fixture.state = "incompatible";
      fixture.protocol = 19;
      fixture.detail = "herdr speaks protocol 19; this shell expects 22.";
      fixture.agents = [];
      fixture.updateSeq = fixture.updateSeq + 1;
      return;
    }

    fixture.workspaces = fixture.workspaceLabels;
    fixture.agents = agents;
    fixture.hasSnapshot = true;
    fixture.protocol = 22;
    fixture.detail = "";
    if (fixture.scenario === "disconnected") {
      fixture.state = "disconnected";
    } else {
      fixture.state = "online";
      fixture.lastSeenMs = Date.now();
      fixture.lastSnapshotMs = Date.now();
    }
    fixture.updateSeq = fixture.updateSeq + 1;
  }

  // Sample-only: actions report what they would do and never reach a session.
  function focusAgent(paneId) {
    fixture.focusSeq = fixture.focusSeq + 1;
    fixture.focusResult(paneId, true, "Sample session · nothing was focused");
  }

  // The refresh is driven by the model (start/refresh) so that the very first
  // snapshot is delivered after the model has connected to this source.
}
