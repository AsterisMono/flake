pragma Singleton
import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Io

// Sway IPC adapter. Workspaces come from Quickshell.I3; windows come from a
// tree snapshot keyed by container id so task buttons stay stable across title
// and focus changes.
Singleton {
  id: desktop

  // Task buttons are ordered by workspace, then by the window's own position on
  // the screen, reading left to right and top to bottom. The first-seen
  // sequence only separates containers that share a position, such as the
  // windows of a tabbed or stacked container.
  property var windows: []
  property int focusedWindowId: -1
  property string focusedMonitorName: ""
  property bool swayConnected: false
  property bool _dirty: false
  property var _order: ({})
  property int _sequence: 1

  readonly property var workspaces: {
    const list = I3.workspaces.values.slice();
    list.sort(function(a, b) {
      const an = a.number >= 0 ? a.number : 10000;
      const bn = b.number >= 0 ? b.number : 10000;
      if (an !== bn)
        return an - bn;
      return String(a.name).localeCompare(String(b.name));
    });
    return list.filter(function(workspace) {
      return workspace.name && workspace.name.indexOf("__i3") !== 0;
    });
  }

  readonly property var focusedWorkspace: I3.focusedWorkspace

  readonly property var workspaceRanks: {
    const ranks = ({});
    const list = desktop.workspaces;
    for (let i = 0; i < list.length; i++)
      ranks[list[i].name] = i;
    return ranks;
  }

  function compareWindows(a, b) {
    const ranks = desktop.workspaceRanks;
    const ar = ranks[a.workspace] !== undefined ? ranks[a.workspace] : 9999;
    const br = ranks[b.workspace] !== undefined ? ranks[b.workspace] : 9999;
    if (ar !== br)
      return ar - br;
    if (a.rectX !== b.rectX)
      return a.rectX - b.rectX;
    if (a.rectY !== b.rectY)
      return a.rectY - b.rectY;
    return a.order - b.order;
  }

  readonly property var focusedScreen: {
    const name = focusedMonitorName;
    if (!name)
      return null;
    const screens = Quickshell.screens;
    for (let i = 0; i < screens.length; i++) {
      if (screens[i] && screens[i].name === name)
        return screens[i];
    }
    return null;
  }

  // True when the workspace visible on a screen holds at least one window.
  // Windows name their workspace, so a workspace no window names is only
  // wallpaper. The window list is read before the monitor lookup on purpose:
  // it is what keeps the bars' color binding live, and it is the only state
  // that changes when a window opens on an empty workspace. The monitor lookup
  // is a plain method call, so it is read fresh on every evaluation; until sway
  // has answered it, the views sway marks visible on the output stand in.
  function workspaceOccupied(screen) {
    const windows = desktop.windows;
    const monitor = screen ? I3.monitorFor(screen) : null;
    const workspace = monitor ? monitor.activeWorkspace : null;

    for (let i = 0; i < windows.length; i++) {
      const window = windows[i];
      if (workspace) {
        if (window.workspace === workspace.name)
          return true;
      } else if (window.visible && screen && window.output === screen.name) {
        return true;
      }
    }

    return false;
  }

  function refresh() {
    if (tree.running) {
      desktop._dirty = true;
      return;
    }
    tree.running = true;
  }

  function refreshSoon() {
    debounce.restart();
  }

  function apply(text) {
    let root;
    try {
      root = JSON.parse(text);
    } catch (error) {
      return;
    }

    const found = [];
    const seen = ({});
    const order = desktop._order;

    function walk(node, workspaceName, outputName) {
      if (!node)
        return;

      if (node.type === "output")
        outputName = node.name || outputName;
      if (node.type === "workspace")
        workspaceName = node.name || workspaceName;

      // Wayland clients name themselves through app_id; an XWayland window
      // carries only its X11 class, which stands in for the same purpose so a
      // task button can find the application's mark either way.
      const appId = node.app_id || (node.window_properties && node.window_properties.class) || "";
      const isContainer = node.type === "con" || node.type === "floating_con";
      const hasWindow = isContainer && (node.window !== null && node.window !== undefined || appId !== "");

      if (hasWindow && workspaceName !== "__i3_scratch" && String(outputName).indexOf("__i3") !== 0) {
        const id = node.id;
        if (order[id] === undefined) {
          order[id] = desktop._sequence;
          desktop._sequence = desktop._sequence + 1;
        }
        seen[id] = true;
        found.push({
          "id": id,
          "title": node.name || appId || "Untitled window",
          "appId": appId,
          // The compositor reports the client pid; it is how a herdr client's
          // hosting terminal is matched to its window.
          "pid": Number(node.pid || 0),
          "workspace": workspaceName,
          "output": outputName,
          // The container's layout position within its workspace; it is what
          // orders windows that share a workspace.
          "rectX": node.rect ? Number(node.rect.x) : 0,
          "rectY": node.rect ? Number(node.rect.y) : 0,
          "focused": node.focused === true,
          "urgent": node.urgent === true,
          "floating": node.type === "floating_con",
          // Sway marks the views it is actually showing on an output; the
          // bars fall back to it when the monitor's workspace is not known.
          "visible": node.visible === true,
          "order": order[id]
        });
      }

      const nodes = node.nodes || [];
      for (let i = 0; i < nodes.length; i++)
        walk(nodes[i], workspaceName, outputName);

      const floating = node.floating_nodes || [];
      for (let i = 0; i < floating.length; i++)
        walk(floating[i], workspaceName, outputName);
    }

    walk(root, "", "");

    for (const key in order) {
      if (!seen[key])
        delete order[key];
    }

    found.sort(function(a, b) {
      return desktop.compareWindows(a, b);
    });

    let focused = -1;
    for (let i = 0; i < found.length; i++) {
      if (found[i].focused) {
        focused = found[i].id;
        break;
      }
    }

    desktop.windows = found;
    desktop.focusedWindowId = focused;
    desktop.swayConnected = true;
    desktop.focusedMonitorName = I3.focusedMonitor ? I3.focusedMonitor.name : "";
  }

  function visibleWindows(capacity) {
    const list = desktop.windows;
    if (capacity <= 0 || list.length <= capacity)
      return list;

    // The bar shows the first slots of the ordered list and, when the focused
    // window falls outside them, swaps it in for the last slot. The result is
    // read back in list order, so the buttons stay sorted.
    const chosen = ({});
    for (let i = 0; i < capacity; i++)
      chosen[i] = true;

    for (let i = 0; i < list.length; i++) {
      if (list[i].focused && !chosen[i]) {
        delete chosen[capacity - 1];
        chosen[i] = true;
        break;
      }
    }

    const visible = [];
    for (let i = 0; i < list.length; i++) {
      if (chosen[i])
        visible.push(list[i]);
    }
    return visible;
  }

  function activateWindow(id) {
    I3.dispatch("[con_id=" + Number(id) + "] focus");
    ShellState.close();
  }

  function closeWindow(id) {
    // Request the close; the task disappears only after the compositor confirms.
    I3.dispatch("[con_id=" + Number(id) + "] kill");
  }

  function activateWorkspace(workspace) {
    if (workspace.number >= 0)
      I3.dispatch("workspace --no-auto-back-and-forth number " + workspace.number);
    else
      I3.dispatch("workspace --no-auto-back-and-forth \"" + String(workspace.name).replace(/(["\\])/g, "\\$1") + "\"");
    ShellState.close();
  }

  function switchWorkspace(workspace, direction) {
    const list = desktop.workspaces;
    let index = -1;
    for (let i = 0; i < list.length; i++) {
      if (list[i] === workspace)
        index = i;
    }
    if (index === -1)
      return;

    const target = Math.max(0, Math.min(list.length - 1, index + (direction > 0 ? 1 : -1)));
    if (target !== index)
      desktop.activateWorkspace(list[target]);
  }

  function workspaceNameFor(id) {
    for (let i = 0; i < desktop.windows.length; i++) {
      if (desktop.windows[i].id === id)
        return desktop.windows[i].workspace;
    }
    return "";
  }

  Timer {
    id: debounce
    interval: 120
    repeat: false
    onTriggered: desktop.refresh()
  }

  // Low-frequency reconciliation covers events missed while disconnected.
  Timer {
    interval: 15000
    running: true
    repeat: true
    onTriggered: desktop.refresh()
  }

  I3IpcListener {
    subscriptions: ["window", "workspace", "output", "shutdown"]
    onIpcEvent: function(event) {
      desktop.refreshSoon();
    }
  }

  Connections {
    target: I3

    function onConnected() {
      desktop.swayConnected = true;
      desktop.refresh();
    }
  }

  Process {
    id: tree
    command: [Runtime.swaymsg, "-t", "get_tree", "-r"]

    stdout: StdioCollector {
      onStreamFinished: desktop.apply(text)
    }

    onExited: function(exitCode, exitStatus) {
      if (desktop._dirty) {
        desktop._dirty = false;
        tree.running = true;
      }
    }
  }

  Component.onCompleted: desktop.refresh()
}
