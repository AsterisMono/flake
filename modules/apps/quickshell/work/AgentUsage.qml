pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Account readings for the work panel. Each source fails independently.
Singleton {
  id: usage

  property bool codexLoaded: false
  property bool codexOk: false
  property var codexWindows: []
  property bool deepseekLoaded: false
  property bool deepseekOk: false
  property var deepseekBalances: []
  property bool openrouterLoaded: false
  property bool openrouterOk: false
  property string openrouterBalance: ""
  property int nowSeconds: Math.floor(Date.now() / 1000)

  function refresh() {
    if (!codexProcess.running) {
      codexProcess.running = true;
    }
    if (!deepseekProcess.running) {
      deepseekProcess.running = true;
    }
    if (!openrouterProcess.running) {
      openrouterProcess.running = true;
    }
  }

  function applyCodex(output) {
    usage.codexLoaded = true;
    try {
      const data = JSON.parse(output);
      usage.codexOk = data.ok === true;
      usage.codexWindows = usage.codexOk ? data.windows : [];
    } catch (error) {
      usage.codexOk = false;
      usage.codexWindows = [];
    }
  }

  function applyDeepseek(output) {
    usage.deepseekLoaded = true;
    try {
      const data = JSON.parse(output);
      usage.deepseekOk = data.ok === true;
      usage.deepseekBalances = usage.deepseekOk ? data.balances : [];
    } catch (error) {
      usage.deepseekOk = false;
      usage.deepseekBalances = [];
    }
  }

  function applyOpenrouter(output) {
    usage.openrouterLoaded = true;
    try {
      const data = JSON.parse(output);
      usage.openrouterOk = data.ok === true && data.balance !== undefined;
      usage.openrouterBalance = usage.openrouterOk ? data.balance + " " + data.currency : "";
    } catch (error) {
      usage.openrouterOk = false;
      usage.openrouterBalance = "";
    }
  }

  function windowLabel(minutes) {
    if (!Number.isFinite(minutes) || minutes <= 0)
      return "limit";
    if (minutes % 10080 === 0)
      return minutes / 10080 + "w";
    if (minutes % 1440 === 0)
      return minutes / 1440 + "d";
    if (minutes % 60 === 0)
      return minutes / 60 + "h";
    return minutes + "m";
  }

  function resetLabel(seconds) {
    if (!Number.isFinite(Number(seconds)) || Number(seconds) <= 0)
      return "reset unknown";
    const minutes = Math.ceil((Number(seconds) - usage.nowSeconds) / 60);
    if (minutes <= 0)
      return "reset due";
    const days = Math.floor(minutes / 1440);
    const hours = Math.floor(minutes % 1440 / 60);
    if (days > 0)
      return "resets in " + days + "d " + hours + "h";
    if (hours > 0)
      return "resets in " + hours + "h " + minutes % 60 + "m";
    return "resets in " + minutes + "m";
  }

  Timer {
    interval: 60000
    running: ShellState.kind === "work"
    repeat: true
    triggeredOnStart: true
    onTriggered: usage.nowSeconds = Math.floor(Date.now() / 1000)
  }

  Timer {
    interval: 300000
    running: ShellState.kind === "work"
    repeat: true
    triggeredOnStart: true
    onTriggered: usage.refresh()
  }

  Process {
    id: codexProcess
    command: [Runtime.agentUsageScript, "codex", Runtime.codexExecutable]
    stdout: StdioCollector {
      onStreamFinished: usage.applyCodex(text)
    }
    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0)
        usage.applyCodex("{}");
    }
  }

  Process {
    id: deepseekProcess
    command: [Runtime.agentUsageScript, "deepseek", Runtime.deepseekKeyPath]
    stdout: StdioCollector {
      onStreamFinished: usage.applyDeepseek(text)
    }
    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0)
        usage.applyDeepseek("{}");
    }
  }

  Process {
    id: openrouterProcess
    command: [Runtime.agentUsageScript, "openrouter", Runtime.openrouterKeyPath]
    stdout: StdioCollector {
      onStreamFinished: usage.applyOpenrouter(text)
    }
    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0)
        usage.applyOpenrouter("{}");
    }
  }
}
