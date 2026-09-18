pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Raise the terminal that hosts the herdr client, but only when process
// ancestry matches exactly one Sway window. Herdr panes belong to the herdr
// server, so a pane has no window of its own.
Singleton {
  id: raise

  function raiseHostWindow() {
    if (Runtime.herdrHostScript === "")
      return;
    hostLookup.running = true;
  }

  function applyHostPids(text) {
    const pids = [];
    const lines = String(text).split("\n");
    for (let i = 0; i < lines.length; i++) {
      const fields = lines[i].trim().split(/\s+/);
      for (let j = 0; j < fields.length; j++) {
        const pid = Number(fields[j]);
        if (pid > 0 && pids.indexOf(pid) === -1)
          pids.push(pid);
      }
    }

    const windows = [];
    for (let i = 0; i < Desktop.windows.length; i++) {
      const window = Desktop.windows[i];
      if (window.pid > 0 && pids.indexOf(window.pid) !== -1 && windows.indexOf(window) === -1)
        windows.push(window);
    }

    if (windows.length === 1)
      Desktop.activateWindow(windows[0].id);
  }

  Process {
    id: hostLookup
    command: [Runtime.herdrHostScript]

    stdout: StdioCollector {
      onStreamFinished: raise.applyHostPids(text)
    }
  }
}
