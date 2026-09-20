pragma Singleton
import QtQuick
import Quickshell
import qs
import qs.work

// Compact bottom-bar summary for work in flight. The model owns counts; this
// file only turns them into the one-line chip the bar renders.
Singleton {
  id: summary

  readonly property bool visible: WorkInFlight.sourceState === "online" || WorkInFlight.sourceState === "incompatible"
  readonly property bool needsYou: WorkInFlight.needsYouCount > 0

  // Blocked agents and agents herdr reports done share one chip: the next step
  // is the user's, which is the same wording the panel uses for its first
  // group. Both counts are live, so the chip clears the moment herdr does.
  readonly property int waitingCount: WorkInFlight.needsYouCount + WorkInFlight.readyCount
  readonly property string waitingWord: summary.waitingCount === 1 ? "needs you" : "need you"

  readonly property var quietPart: {
    switch (WorkInFlight.sourceState) {
    case "online":
      // "no agents" reads as a fact about the session; "0 idle" reads as a
      // count that failed to arrive.
      return {
        "icon": "agentIdle",
        "text": WorkInFlight.agents.length === 0 ? "no agents" : WorkInFlight.agents.length + " idle",
        "color": Theme.muted
      };
    case "incompatible":
      return { "icon": "agentAttention", "text": "unsupported", "color": Theme.attention };
    default:
      return { "icon": "agentIdle", "text": "connecting", "color": Theme.muted };
    }
  }

  function parts(compact) {
    const list = [];
    if (WorkInFlight.workingCount > 0)
      list.push({ "icon": "agentWorking", "text": compact ? String(WorkInFlight.workingCount) : WorkInFlight.workingCount + " working", "color": Theme.text });
    if (WorkInFlight.idleCount > 0)
      list.push({ "icon": "agentIdle", "text": compact ? String(WorkInFlight.idleCount) : WorkInFlight.idleCount + " idle", "color": Theme.muted });
    if (summary.waitingCount > 0)
      list.push({ "icon": "agentAttention", "text": compact ? String(summary.waitingCount) : summary.waitingCount + " " + summary.waitingWord, "color": Theme.attention });
    if (list.length === 0)
      list.push(summary.quietPart);
    return list;
  }

  readonly property var compactParts: summary.parts(true)
  readonly property var fullParts: summary.parts(false)
}
