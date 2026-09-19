pragma Singleton
import QtQuick
import Quickshell
import qs
import qs.work

// Normalized "work in flight" model.
//
// A live projection of what herdr reports, and nothing else: rows and counts
// come from the current agent list, so a completion stops waiting the moment
// herdr stops calling that agent done. The shell keeps no history of its own,
// and connection freshness stays separate from agent state: a lost socket is
// not an agent failure. Herdr owns agent state; the shell only reports it.
// Bar wording lives in WorkSummary; raising a terminal lives in WorkRaise.
Singleton {
  id: work

  readonly property string fixtureScenario: Quickshell.env("QS_WORK_FIXTURE") || ""
  readonly property bool fixture: fixtureScenario !== ""
  readonly property var source: work.fixture ? FixtureSource : HerdrClient

  property double nowMs: Date.now()

  readonly property var agents: source.agents
  readonly property string sourceState: source.state
  readonly property bool fresh: source.state === "online"
  readonly property bool hasSnapshot: source.hasSnapshot === true
  readonly property double lastSeenMs: source.lastSeenMs

  readonly property var workingAgents: work.agentsWithState("working")
  readonly property var blockedAgents: work.agentsWithState("blocked")
  readonly property var doneAgents: work.agentsWithState("done")
  readonly property var otherAgents: work.agentsWithState("idle").concat(work.agentsWithState("unknown"))

  readonly property int needsYouCount: work.blockedAgents.length
  readonly property int workingCount: work.workingAgents.length
  readonly property int readyCount: work.doneAgents.length
  readonly property int idleCount: work.otherAgents.length

  readonly property var needsRows: work.rowsFromAgents(work.blockedAgents, "needs")
  readonly property var readyRows: work.rowsFromAgents(work.doneAgents, "ready")
  readonly property var workingRows: work.rowsFromAgents(work.workingAgents, "working")
  readonly property var idleRows: work.rowsFromAgents(work.otherAgents, "idle")

  readonly property string sourceLine: {
    if (work.fixture)
      return "Sample data · fixture mode (" + work.fixtureScenario + ")";
    switch (work.sourceState) {
    case "online":
      if (!work.hasSnapshot)
        return source.lastError !== "" ? "Connected to " + source.serviceLabel + ", but " + source.lastError + "." : "Connected to " + source.serviceLabel + "; waiting for the first snapshot.";
      return source.serviceLabel + " · " + work.agents.length + (work.agents.length === 1 ? " agent" : " agents");
    case "connecting":
      return "Connecting to " + source.serviceLabel + "…";
    case "disconnected":
      return work.lastSeenMs > 0 ? "Disconnected — last seen " + work.relative(work.lastSeenMs) + ". Showing what herdr last reported." : "herdr is not reachable. Nothing to show.";
    case "incompatible":
      return source.detail !== "" ? source.detail : "This herdr protocol is not supported.";
    case "unconfigured":
      return "herdr is not configured.";
    default:
      return "herdr state unavailable.";
    }
  }

  readonly property bool sourceTrouble: work.sourceState !== "online"

  // -- source plumbing -----------------------------------------------------

  function agentsWithState(state) {
    const list = work.agents;
    const result = [];
    for (let i = 0; i < list.length; i++) {
      if (list[i].state === state)
        result.push(list[i]);
    }
    return result;
  }

  function workspaceLabel(workspaceId) {
    if (!workspaceId)
      return "";
    const labels = source.workspaces;
    const entry = labels ? labels[workspaceId] : null;
    return entry && entry.label ? String(entry.label) : String(workspaceId);
  }

  function shortPath(path) {
    const value = String(path || "");
    if (value === "")
      return "";
    const home = Runtime.homeDirectory;
    if (home !== "" && value.indexOf(home) === 0)
      return "~" + value.slice(home.length);
    return value;
  }

  function relative(timeMs) {
    if (!timeMs)
      return "unknown";
    const seconds = Math.max(0, Math.round((work.nowMs - timeMs) / 1000));
    if (seconds < 45)
      return "just now";
    const minutes = Math.round(seconds / 60);
    if (minutes < 60)
      return minutes + " min ago";
    const hours = Math.round(minutes / 60);
    if (hours < 24)
      return hours + " h ago";
    return Math.round(hours / 24) + " d ago";
  }

  // -- rows ----------------------------------------------------------------

  function rowsFromAgents(list, group) {
    const rows = [];
    for (let i = 0; i < list.length; i++)
      rows.push(work.agentRow(list[i], group));
    return rows;
  }

  function contextLine(displayName, workspaceId, cwd) {
    const parts = [];
    if (displayName !== "")
      parts.push(displayName);
    const workspace = work.workspaceLabel(workspaceId);
    if (workspace !== "")
      parts.push(workspace);
    const project = work.shortPath(cwd);
    if (project !== "")
      parts.push(project);
    return parts.join(" · ");
  }

  function timeText(prefix, timeMs) {
    if (!timeMs)
      return "";
    return prefix + " " + work.relative(timeMs);
  }

  function agentRow(agent, group) {
    let stateLabel = "Idle";
    let stateIcon = "";
    let stateColor = Theme.dim;
    let note = "";
    if (agent.state === "working") {
      stateLabel = "Working";
      stateIcon = "clock";
      stateColor = Theme.muted;
    } else if (agent.state === "blocked") {
      stateLabel = "Needs you";
      stateIcon = "blocked";
      stateColor = Theme.amber;
      note = "Herdr reports blocked; input may be needed.";
    } else if (agent.state === "done") {
      stateLabel = "Ready to review";
      stateIcon = "ready";
      stateColor = Theme.accent;
      note = "Herdr reports done. Ready for your review.";
    } else if (agent.state === "unknown") {
      stateLabel = "State unavailable";
      stateColor = Theme.dim;
      note = "Herdr cannot classify this agent right now.";
    }

    const title = agent.title !== "" ? agent.title : (agent.displayName !== "" ? agent.displayName : "Agent");
    return {
      "group": group,
      "paneId": agent.paneId,
      "title": title,
      "context": work.contextLine(agent.displayName, agent.workspaceId, agent.cwd),
      "stateLabel": stateLabel,
      "stateIcon": stateIcon,
      "stateColor": stateColor,
      "note": note,
      "timeText": work.fresh ? "" : work.timeText("last seen", agent.observedAtMs),
      "openable": agent.paneId !== "" && work.sourceState !== "incompatible"
    };
  }

  // -- actions -------------------------------------------------------------

  function refresh() {
    work.nowMs = Date.now();
    source.refresh();
  }

  function open(row) {
    if (!row.openable)
      return;
    source.focusAgent(row.paneId);
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: work.nowMs = Date.now()
  }

  Connections {
    target: work.source

    function onFocusResult(paneId, ok, message) {
      if (!ok)
        return;
      if (!work.fixture)
        WorkRaise.raiseHostWindow();
    }
  }

  Component.onCompleted: {
    work.nowMs = Date.now();
    source.start();
  }
}
