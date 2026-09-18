pragma Singleton
import QtQuick
import Quickshell
import qs
import qs.work

// Normalized "work in flight" model.
//
// Source state, connection freshness and local acknowledgement stay separate:
// a lost socket is not an agent failure, and dismissing a ready record is not
// an agent state change. Herdr owns agent state; the shell only reports it.
// Bar wording lives in WorkSummary; raising a terminal lives in WorkRaise.
Singleton {
  id: work

  readonly property string fixtureScenario: Quickshell.env("QS_WORK_FIXTURE") || ""
  readonly property bool fixture: fixtureScenario !== ""
  readonly property var source: work.fixture ? FixtureSource : HerdrClient

  property var records: []
  property bool historyCapped: false
  property string pendingAcknowledgeKey: ""
  property double nowMs: Date.now()

  readonly property int historyLimit: 100

  readonly property var agents: source.agents
  readonly property string sourceState: source.state
  readonly property bool fresh: source.state === "online"
  readonly property bool hasSnapshot: source.hasSnapshot === true
  readonly property double lastSeenMs: source.lastSeenMs

  readonly property var workingAgents: work.agentsWithState("working")
  readonly property var blockedAgents: work.agentsWithState("blocked")
  readonly property var otherAgents: work.agentsWithState("idle").concat(work.agentsWithState("unknown"))

  readonly property var readyRecords: work.records.filter(function(record) {
    return !record.acknowledged;
  })

  readonly property int needsYouCount: work.blockedAgents.length
  readonly property int workingCount: work.workingAgents.length
  readonly property int readyCount: work.readyRecords.length
  readonly property int idleCount: work.otherAgents.length

  readonly property var needsRows: work.rowsFromAgents(work.blockedAgents, "needs")
  readonly property var readyRows: work.rowsFromRecords(work.readyRecords)
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

  function recordKey(agent) {
    const endpoint = work.fixture ? "fixture" : Runtime.herdrEndpoint;
    return endpoint + "|" + agent.terminalId + "|" + agent.paneId + (agent.sessionKey !== "" ? "|" + agent.sessionKey : "");
  }

  function recordFromAgent(agent, noticedAtMs) {
    return {
      "key": work.recordKey(agent),
      "paneId": agent.paneId,
      "terminalId": agent.terminalId,
      "workspaceId": agent.workspaceId,
      "sessionKey": agent.sessionKey,
      "agentName": agent.agentName,
      "displayName": agent.displayName,
      "title": agent.title,
      "cwd": agent.cwd,
      "stateChangeSeq": agent.stateChangeSeq,
      "noticedAtMs": noticedAtMs,
      "observedAtMs": noticedAtMs,
      "acknowledged": false,
      "ended": false,
      "liveState": "done"
    };
  }

  // Reconcile the retained readiness records against the latest authoritative
  // snapshot. A later working → done transition carries a new state-change
  // sequence and therefore creates a new record; metadata revisions, renames
  // and reconnects do not.
  function reconcile() {
    const live = work.agents;
    const seen = Date.now();
    let next = work.records.slice();

    for (let i = 0; i < live.length; i++) {
      const agent = live[i];
      const key = work.recordKey(agent);
      let index = -1;
      for (let j = 0; j < next.length; j++) {
        if (next[j].key === key)
          index = j;
      }

      if (agent.state === "done") {
        if (index === -1) {
          next.push(work.recordFromAgent(agent, seen));
        } else if (next[index].stateChangeSeq !== agent.stateChangeSeq) {
          next[index] = work.recordFromAgent(agent, seen);
        } else {
          next[index] = work.refreshRecord(next[index], agent, seen);
        }
        continue;
      }

      if (index !== -1) {
        next[index] = work.refreshRecord(next[index], agent, seen);
      }
    }

    const liveKeys = { };
    for (let i = 0; i < live.length; i++)
      liveKeys[work.recordKey(live[i])] = true;

    for (let i = 0; i < next.length; i++) {
      if (liveKeys[next[i].key])
        continue;
      if (work.fresh && !next[i].ended)
        next[i] = work.withField(work.withField(next[i], "ended", true), "liveState", "");
    }

    if (next.length > work.historyLimit) {
      next = work.prune(next);
    }

    work.records = next;
  }

  function refreshRecord(record, agent, seen) {
    const updated = work.withField(record, "title", agent.title !== "" ? agent.title : record.title);
    updated.cwd = agent.cwd !== "" ? agent.cwd : record.cwd;
    updated.agentName = agent.agentName !== "" ? agent.agentName : record.agentName;
    updated.displayName = agent.displayName !== "" ? agent.displayName : record.displayName;
    updated.workspaceId = agent.workspaceId;
    updated.liveState = agent.state;
    updated.ended = false;
    updated.observedAtMs = seen;
    return updated;
  }

  function withField(record, field, value) {
    const copy = { };
    for (const key in record)
      copy[key] = record[key];
    copy[field] = value;
    return copy;
  }

  function prune(list) {
    const acknowledged = [];
    const pending = [];
    for (let i = 0; i < list.length; i++) {
      if (list[i].acknowledged || list[i].ended)
        acknowledged.push(list[i]);
      else
        pending.push(list[i]);
    }
    acknowledged.sort(function(a, b) {
      return b.noticedAtMs - a.noticedAtMs;
    });
    const keep = pending.concat(acknowledged.slice(0, Math.max(0, work.historyLimit - pending.length)));
    keep.sort(function(a, b) {
      return b.noticedAtMs - a.noticedAtMs;
    });
    work.historyCapped = true;
    return keep;
  }

  // -- rows ----------------------------------------------------------------

  function rowsFromAgents(list, group) {
    const rows = [];
    for (let i = 0; i < list.length; i++)
      rows.push(work.agentRow(list[i], group));
    return rows;
  }

  function rowsFromRecords(list) {
    const rows = [];
    for (let i = 0; i < list.length; i++)
      rows.push(work.recordRow(list[i]));
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
      stateLabel = "Ready";
      stateIcon = "ready";
      stateColor = Theme.accent;
    } else if (agent.state === "unknown") {
      stateLabel = "State unavailable";
      stateColor = Theme.dim;
      note = "Herdr cannot classify this agent right now.";
    }

    const title = agent.title !== "" ? agent.title : (agent.displayName !== "" ? agent.displayName : "Agent");
    return {
      "group": group,
      "recordKey": "",
      "paneId": agent.paneId,
      "title": title,
      "context": work.contextLine(agent.displayName, agent.workspaceId, agent.cwd),
      "stateLabel": stateLabel,
      "stateIcon": stateIcon,
      "stateColor": stateColor,
      "note": note,
      "timeText": work.fresh ? "" : work.timeText("last seen", agent.observedAtMs),
      "ended": false,
      "stale": !work.fresh,
      "acknowledged": false,
      "liveState": agent.state,
      "openable": agent.paneId !== "" && work.sourceState !== "incompatible"
    };
  }

  function recordRow(record) {
    const liveAgent = work.findAgent(record.paneId);
    let note = "Herdr reports done. Ready for your review.";
    if (record.ended)
      note = "This session has ended. It was last seen " + work.relative(record.observedAtMs || record.noticedAtMs) + ".";
    else if (liveAgent && liveAgent.state !== "done")
      note = "Now " + work.stateWord(liveAgent.state) + "; this earlier review record is retained.";

    const title = record.title !== "" ? record.title : (record.displayName !== "" ? record.displayName : "Agent");
    return {
      "group": "ready",
      "recordKey": record.key,
      "paneId": record.paneId,
      "title": title,
      "context": work.contextLine(record.displayName, record.workspaceId, record.cwd),
      "stateLabel": "Ready to review",
      "stateIcon": "ready",
      "stateColor": Theme.accent,
      "note": note,
      "timeText": work.timeText("noticed", record.noticedAtMs),
      "ended": record.ended,
      "stale": !work.fresh,
      "acknowledged": record.acknowledged,
      "liveState": record.liveState || "",
      "openable": !record.ended && record.paneId !== "" && work.sourceState !== "incompatible"
    };
  }

  function findAgent(paneId) {
    for (let i = 0; i < work.agents.length; i++) {
      if (work.agents[i].paneId === paneId)
        return work.agents[i];
    }
    return null;
  }

  function stateWord(state) {
    switch (state) {
    case "working":
      return "working";
    case "blocked":
      return "waiting for you";
    case "idle":
      return "idle";
    case "done":
      return "ready to review";
    default:
      return "unclassified";
    }
  }

  // -- actions -------------------------------------------------------------

  function refresh() {
    work.nowMs = Date.now();
    source.refresh();
  }

  function open(row) {
    if (!row.openable)
      return;
    work.pendingAcknowledgeKey = row.recordKey;
    source.focusAgent(row.paneId);
  }

  function acknowledge(key, acknowledged) {
    const next = [];
    for (let i = 0; i < work.records.length; i++) {
      const record = work.records[i];
      next.push(record.key === key ? work.withField(record, "acknowledged", acknowledged) : record);
    }
    work.records = next;
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: work.nowMs = Date.now()
  }

  Connections {
    target: work.source

    function onUpdateSeqChanged() {
      work.reconcile();
    }
  }

  Connections {
    target: work.source

    function onFocusResult(paneId, ok, message) {
      if (!ok) {
        work.pendingAcknowledgeKey = "";
        return;
      }
      if (work.pendingAcknowledgeKey !== "") {
        work.acknowledge(work.pendingAcknowledgeKey, true);
        work.pendingAcknowledgeKey = "";
      }
      if (!work.fixture)
        WorkRaise.raiseHostWindow();
    }
  }

  Component.onCompleted: {
    work.nowMs = Date.now();
    source.start();
    work.reconcile();
  }
}
