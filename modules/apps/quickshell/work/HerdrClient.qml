pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Herdr socket adapter (herdr 0.9.x, protocol 22).
//
// Wire behavior verified against the live socket on 2026-09-18:
//   * newline-delimited JSON; a request is {id, method, params}
//   * the server answers exactly one request per connection and then closes
//     it, so every request needs its own short-lived connection
//   * `events.subscribe` is the one long-lived connection, and it also accepts
//     exactly one request: changing the subscription set (for example when a
//     pane starts hosting an agent) means opening a new subscription
//
// The adapter owns connection lifecycle, framing and request correlation. It
// never infers agent state from terminal text.
Singleton {
  id: client

  readonly property string endpoint: Runtime.herdrEndpoint
  readonly property bool configured: endpoint !== ""

  // unconfigured | connecting | online | disconnected | incompatible
  property string state: configured ? "connecting" : "unconfigured"
  property string serviceVersion: ""
  property int protocol: 0
  property string detail: ""
  property double lastSeenMs: 0
  property double lastSnapshotMs: 0
  property bool hasSnapshot: false
  property int updateSeq: 0
  property var agents: []
  property var workspaces: ({})
  property string lastError: ""
  property int focusSeq: 0

  readonly property string serviceLabel: serviceVersion !== "" ? "herdr " + serviceVersion : "herdr"
  // Transport truth, separate from the interpreted source state.
  readonly property bool subscriptionConnected: client._eventSocket !== null && client._eventSocket.connected

  signal focusResult(string paneId, bool ok, string message)

  // -- configuration -------------------------------------------------------

  readonly property int expectedProtocol: 22
  readonly property int requestTimeoutMs: 4000
  readonly property int frameLimit: 262144

  // -- public actions ------------------------------------------------------

  function start() {
    if (!client.configured || client._started)
      return;
    client._started = true;
    client._connectSubscription();
  }

  function stop() {
    client._started = false;
    client._closeSubscription();
  }

  function retry() {
    client._started = true;
    client._backoffStep = 0;
    client._closeSubscription();
    client._connectSubscription();
  }

  // Read-only refresh. Coalesced: several invalidations in a row produce one
  // snapshot request, and a request that arrives mid-flight is remembered.
  function refresh() {
    if (!client.configured)
      return;
    if (client._refreshing) {
      client._refreshQueued = true;
      return;
    }

    client._refreshing = true;
    client._request("session.snapshot", { }, function(ok, result, message) {
      client._refreshing = false;
      if (ok)
        client._applySnapshot(result.snapshot);
      else
        client._noteRequestFailure(message);
      if (client._refreshQueued) {
        client._refreshQueued = false;
        client.refresh();
      }
    });
  }

  function focusAgent(paneId) {
    if (!client.configured || paneId === "")
      return;
    const target = paneId;
    client._request("agent.focus", { "target": target }, function(ok, result, message) {
      client.focusSeq = client.focusSeq + 1;
      client.focusResult(target, ok, ok ? "" : message);
      if (ok)
        client.refresh();
    });
  }

  // -- reachability --------------------------------------------------------

  property bool _started: false
  property bool _closedByUs: false
  property bool _subscribed: false
  property bool _refreshing: false
  property bool _refreshQueued: false
  property int _backoffStep: 0
  property int _failureStreak: 0
  property string _paneKey: ""
  property int _requestSeq: 1
  property var _queue: []
  property var _active: null
  property var _eventSocket: null
  property bool _subscribeWritten: false

  readonly property var baseSubscriptions: [
    { "type": "pane.created" },
    { "type": "pane.closed" },
    { "type": "pane.updated" },
    { "type": "pane.exited" },
    { "type": "pane.agent_detected" },
    { "type": "workspace.created" },
    { "type": "workspace.updated" },
    { "type": "workspace.closed" },
    { "type": "workspace.renamed" },
    { "type": "tab.created" },
    { "type": "tab.closed" }
  ]

  function _paneKeyFor(agentList) {
    const ids = [];
    for (let i = 0; i < agentList.length; i++)
      ids.push(String(agentList[i].paneId));
    ids.sort();
    return ids.join(",");
  }

  // The subscription owns a freshly created socket per attempt. Reusing one
  // QLocalSocket after it has been closed or has errored does not reliably
  // reconnect, and a silent failure there would leave the panel claiming a
  // connection it does not have.
  function _connectSubscription() {
    if (!client.configured || !client._started || client.subscriptionConnected)
      return;
    client._closeSubscription();
    client._closedByUs = false;
    client._subscribed = false;
    client._subscribeWritten = false;
    if (client.state !== "incompatible")
      client.state = "connecting";

    const socket = eventComponent.createObject(client, { "path": client.endpoint });
    if (!socket) {
      client._noteRequestFailure("could not open the herdr subscription socket");
      client._scheduleReconnect();
      return;
    }
    client._eventSocket = socket;
    socket.connected = true;
    connectWatchdog.restart();
    subscribeHandshake.restart();
  }

  function _subscribeAgain() {
    client._closeSubscription();
    client._connectSubscription();
  }

  // Writing the subscription is not the same as being connected: the socket
  // can report a pending connection, and a resumed connection can be reported
  // without a fresh state change. This writes once per connection attempt, and
  // the handshake watchdog below forces a fresh connection if nothing comes
  // back.
  function _writeSubscription(socket) {
    if (client._subscribeWritten || socket !== client._eventSocket || !socket.connected)
      return;
    client._subscribeWritten = true;
    socket.write(JSON.stringify(client._subscriptionPayload()) + "\n");
    socket.flush();
    subscribeHandshake.restart();
  }

  function _closeSubscription() {
    const socket = client._eventSocket;
    client._eventSocket = null;
    if (!socket)
      return;
    client._closedByUs = true;
    try {
      socket.connected = false;
    } catch (error) {
      // The socket may already be gone.
    }
    socket.destroy();
  }

  function _subscriptionPayload() {
    const subscriptions = client.baseSubscriptions.slice();
    const list = client.agents;
    for (let i = 0; i < list.length; i++)
      subscriptions.push({ "type": "pane.agent_status_changed", "pane_id": String(list[i].paneId) });
    return { "id": "shell-subscription", "method": "events.subscribe", "params": { "subscriptions": subscriptions } };
  }

  function _handleSubscriptionClosed(socket) {
    if (socket !== undefined && socket !== null && socket !== client._eventSocket)
      return;
    if (client._closedByUs)
      return;
    client._eventSocket = null;
    const wasSubscribed = client._subscribed;
    client._subscribed = false;
    if (wasSubscribed)
      client.hasSnapshot = false;
    if (client.state === "incompatible")
      return;
    client.state = "disconnected";
    client.updateSeq = client.updateSeq + 1;
    client._scheduleReconnect();
  }

  function _scheduleReconnect() {
    if (!client._started || !client.configured || reconnectTimer.running)
      return;
    const steps = [2000, 4000, 8000, 15000, 30000, 60000];
    reconnectTimer.interval = steps[Math.min(client._backoffStep, steps.length - 1)];
    reconnectTimer.restart();
  }

  function _handleEventLine(line) {
    if (line.length > client.frameLimit) {
      client._subscribeAgain();
      return;
    }

    let envelope;
    try {
      envelope = JSON.parse(line);
    } catch (error) {
      client.detail = "Ignoring a malformed herdr frame.";
      return;
    }

    if (envelope.id === "shell-subscription") {
      if (envelope.error) {
        client._noteRequestFailure(envelope.error.message || envelope.error.code || "subscription refused");
        return;
      }
      client._subscribed = true;
      client._backoffStep = 0;
      client._failureStreak = 0;
      connectWatchdog.stop();
      subscribeHandshake.stop();
      client.state = "online";
      client.lastSeenMs = Date.now();
      client.detail = "";
      client.updateSeq = client.updateSeq + 1;
      client.refresh();
      return;
    }

    if (envelope.event !== undefined) {
      // Events are invalidations; authoritative state always comes from a
      // snapshot or agent fetch.
      client.invalidate();
    }
  }

  function invalidate() {
    if (!client._started)
      return;
    invalidateTimer.restart();
  }

  function _applySnapshot(snapshot) {
    if (!snapshot || !snapshot.agents) {
      client._noteRequestFailure("herdr returned an empty snapshot");
      return;
    }

    const protocol = Number(snapshot.protocol || 0);
    if (protocol !== 0 && protocol !== client.expectedProtocol) {
      client.protocol = protocol;
      client.state = "incompatible";
      client.detail = "herdr speaks protocol " + protocol + "; this shell expects " + client.expectedProtocol + ".";
      client.updateSeq = client.updateSeq + 1;
      return;
    }

    client.protocol = protocol;
    client.serviceVersion = String(snapshot.version || "");

    const labels = { };
    const workspaces = snapshot.workspaces || [];
    for (let i = 0; i < workspaces.length; i++) {
      const workspace = workspaces[i];
      labels[String(workspace.workspace_id)] = {
        "label": String(workspace.label || workspace.workspace_id),
        "number": workspace.number,
        "focused": workspace.focused === true
      };
    }

    const seen = Date.now();
    const normalized = [];
    const source = snapshot.agents || [];
    for (let i = 0; i < source.length; i++) {
      const agent = source[i];
      const session = agent.agent_session;
      normalized.push({
        "paneId": String(agent.pane_id || ""),
        "terminalId": String(agent.terminal_id || ""),
        "workspaceId": String(agent.workspace_id || ""),
        "tabId": String(agent.tab_id || ""),
        "sessionKey": session ? String(session.source) + ":" + String(session.value) : "",
        "agentName": String(agent.agent || ""),
        "displayName": String(agent.display_agent || agent.agent || ""),
        "title": client.cleanTitle(agent.terminal_title_stripped || agent.terminal_title || agent.title || ""),
        "cwd": String(agent.foreground_cwd || agent.cwd || ""),
        "focused": agent.focused === true,
        "state": String(agent.agent_status || "unknown"),
        "stateChangeSeq": Number(agent.state_change_seq || 0),
        "revision": Number(agent.revision || 0),
        "observedAtMs": seen
      });
    }

    client.workspaces = labels;
    client.agents = normalized;
    client.lastSeenMs = seen;
    client.lastSnapshotMs = seen;
    client.hasSnapshot = true;
    client.state = client._subscribed ? "online" : client.state;
    client.detail = "";
    client.updateSeq = client.updateSeq + 1;

    const paneKey = client._paneKeyFor(normalized);
    if (paneKey !== client._paneKey) {
      client._paneKey = paneKey;
      if (client._subscribed)
        client._subscribeAgain();
    }
  }

  function cleanTitle(raw) {
    let title = String(raw).replace(/[\u0000-\u001f\u007f]+/g, " ");
    title = title.replace(/\s+/g, " ").trim();
    if (title.length > 160)
      title = title.slice(0, 159) + "…";
    return title;
  }

  // -- request plumbing ----------------------------------------------------

  function _request(method, params, callback) {
    if (!client.configured) {
      if (callback)
        callback(false, null, "herdr is not configured");
      return;
    }

    const id = "shell-" + client._requestSeq;
    client._requestSeq = client._requestSeq + 1;
    client._queue = client._queue.concat([{
      "id": id,
      "method": method,
      "params": params,
      "callback": callback,
      "payload": JSON.stringify({ "id": id, "method": method, "params": params }) + "\n"
    }]);
    client._pump();
  }

  function _pump() {
    if (client._active !== null || client._queue.length === 0)
      return;

    const queue = client._queue.slice();
    const request = queue.shift();
    client._queue = queue;

    const socket = requestComponent.createObject(client, { "path": client.endpoint });
    if (!socket) {
      if (request.callback)
        request.callback(false, null, "could not open the herdr socket");
      client._noteRequestFailure("could not open the herdr socket");
      return;
    }

    socket.requestId = request.id;
    socket.payload = request.payload;
    socket.startedAtMs = Date.now();
    client._active = {
      "socket": socket,
      "request": request,
      "startedAtMs": socket.startedAtMs
    };
    socket.connected = true;
  }

  function _handleRequestLine(socket, line) {
    if (client._active === null || client._active.socket !== socket || socket.settled)
      return;
    if (line.length > client.frameLimit) {
      client._settleRequest(socket, false, null, "herdr sent an oversized frame");
      return;
    }

    let envelope;
    try {
      envelope = JSON.parse(line);
    } catch (error) {
      return;
    }

    if (envelope.id !== socket.requestId)
      return;
    if (envelope.error)
      client._settleRequest(socket, false, null, envelope.error.message || envelope.error.code || "herdr refused the request");
    else
      client._settleRequest(socket, true, envelope.result || { }, "");
  }

  function _settleRequest(socket, ok, result, message) {
    socket.settled = true;
    const active = client._active;
    client._active = null;

    try {
      socket.connected = false;
    } catch (error) {
      // The server has usually closed the connection already.
    }
    socket.destroy();

    if (ok) {
      client._failureStreak = 0;
    } else {
      client.lastError = message;
      client._noteRequestFailure(message);
    }

    if (active && active.request.callback)
      active.request.callback(ok, result, message);

    client._pump();
  }

  // A request failing is not proof that the session is gone; only repeated
  // failures while we still believe we are subscribed force a reconnect.
  function _noteRequestFailure(message) {
    client.lastError = message;
    client._failureStreak = client._failureStreak + 1;
    if (client._failureStreak >= 3 && client.state === "online") {
      client.state = "disconnected";
      client.updateSeq = client.updateSeq + 1;
      client._closeSubscription();
      client._scheduleReconnect();
    }
  }

  Component {
    id: requestComponent

    Socket {
      id: requestSocket

      property string requestId: ""
      property string payload: ""
      property double startedAtMs: 0
      property bool sent: false
      property bool settled: false

      parser: SplitParser {
        splitMarker: "\n"

        onRead: function(line) {
          client._handleRequestLine(requestSocket, line);
        }
      }

      onConnectionStateChanged: {
        if (requestSocket.connected && !requestSocket.sent) {
          requestSocket.sent = true;
          requestSocket.write(requestSocket.payload);
          requestSocket.flush();
        } else if (!requestSocket.connected && requestSocket.sent && !requestSocket.settled) {
          client._settleRequest(requestSocket, false, null, "herdr closed the connection without a reply");
        }
      }

      onError: function(error) {
        if (!requestSocket.settled)
          client._settleRequest(requestSocket, false, null, "socket error " + error);
      }
    }
  }

  // The long-lived event connection. It carries the subscription and stays
  // open for invalidations; every other request uses its own connection. One
  // object is created per attempt so a closed or failed socket never has to be
  // revived in place.
  Component {
    id: eventComponent

    Socket {
      id: eventSocket

      parser: SplitParser {
        splitMarker: "\n"

        onRead: function(line) {
          if (eventSocket === client._eventSocket)
            client._handleEventLine(line);
        }
      }

      onConnectionStateChanged: {
        if (eventSocket !== client._eventSocket)
          return;
        if (eventSocket.connected) {
          client._subscribed = false;
          client._writeSubscription(eventSocket);
        } else {
          client._handleSubscriptionClosed(eventSocket);
        }
      }

      onError: function(error) {
        if (eventSocket !== client._eventSocket)
          return;
        // A refused attempt can report its error after a newer attempt already
        // connected; only a genuinely closed socket counts as a loss.
        if (eventSocket.connected || !client._started)
          return;
        client._handleSubscriptionClosed(eventSocket);
      }
    }
  }

  Timer {
    id: invalidateTimer
    interval: 300
    repeat: false
    onTriggered: client.refresh()
  }

  Timer {
    id: reconnectTimer
    repeat: false
    onTriggered: {
      client._backoffStep = Math.min(client._backoffStep + 1, 5);
      client._connectSubscription();
    }
  }

  // A refused or missing socket must not leave the panel claiming that it is
  // still connecting, even if no connection-state signal arrives.
  Timer {
    id: connectWatchdog
    interval: 3000
    repeat: false
    onTriggered: {
      if (client.subscriptionConnected || client.state === "incompatible")
        return;
      client.state = "disconnected";
      client.updateSeq = client.updateSeq + 1;
      client._scheduleReconnect();
    }
  }

  // If a connection is up but the subscription was never acknowledged (a
  // write that landed before the socket was ready, for example), cycle the
  // connection instead of writing twice on the same one.
  Timer {
    id: subscribeHandshake
    interval: 2500
    repeat: false
    onTriggered: {
      if (client._subscribed || !client._started || !client.configured)
        return;
      client._subscribeAgain();
    }
  }

  // A low-frequency reconciliation covers invalidations missed while the
  // subscription was being replaced.
  Timer {
    interval: 20000
    running: client._started && client.configured
    repeat: true
    onTriggered: client.refresh()
  }

  Timer {
    interval: 1000
    running: client._active !== null
    repeat: true
    onTriggered: {
      const active = client._active;
      if (active !== null && Date.now() - active.startedAtMs > client.requestTimeoutMs)
        client._settleRequest(active.socket, false, null, "herdr did not answer in time");
    }
  }

  Component.onCompleted: {
    if (!client.configured)
      client.state = "unconfigured";
  }
}
