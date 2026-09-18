pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared /proc sampler. One process serves every output.
Singleton {
  id: health

  property bool valid: false
  property bool stale: false
  property real lastUpdate: 0

  property string iface: ""
  property real netUp: 0
  property real netDown: 0

  property real memoryUsed: 0
  property real memoryTotal: 0
  property real swapUsed: 0
  property real swapTotal: 0
  property real zswap: 0
  property real zswapped: 0

  property real psiSome10: 0
  property real psiSome60: 0
  property real psiSome300: 0
  property real psiFull10: 0
  property real psiFull60: 0
  property real psiFull300: 0

  property bool hasTemp: false
  property real temperature: 0

  property int failedSystem: 0
  property int failedUser: 0

  readonly property bool netValid: iface !== ""
  readonly property real memoryPercent: memoryTotal > 0 ? (memoryUsed / memoryTotal) * 100 : 0
  readonly property int failedTotal: failedSystem + failedUser

  // Hidden at zero; warning at 5% and critical at 20% of some avg60.
  readonly property int pressureLevel: !valid ? 0 : psiSome60 >= 20 ? 2 : psiSome60 >= 5 ? 1 : 0

  function apply(text) {
    let data;
    try {
      data = JSON.parse(text);
    } catch (error) {
      health.fail();
      return;
    }

    health.iface = data.iface || "";
    health.netUp = Number(data.netUp) || 0;
    health.netDown = Number(data.netDown) || 0;
    health.memoryUsed = Number(data.memUsed) || 0;
    health.memoryTotal = Number(data.memTotal) || 0;
    health.swapUsed = Number(data.swapUsed) || 0;
    health.swapTotal = Number(data.swapTotal) || 0;
    health.zswap = Number(data.zswap) || 0;
    health.zswapped = Number(data.zswapped) || 0;
    health.psiSome10 = Number(data.psiSome10) || 0;
    health.psiSome60 = Number(data.psiSome60) || 0;
    health.psiSome300 = Number(data.psiSome300) || 0;
    health.psiFull10 = Number(data.psiFull10) || 0;
    health.psiFull60 = Number(data.psiFull60) || 0;
    health.psiFull300 = Number(data.psiFull300) || 0;
    health.failedSystem = Number(data.failedSystem) || 0;
    health.failedUser = Number(data.failedUser) || 0;

    if (data.temp === null || data.temp === undefined) {
      health.hasTemp = false;
      health.temperature = 0;
    } else {
      health.hasTemp = true;
      health.temperature = Number(data.temp);
    }

    health.valid = true;
    health.stale = false;
    health.lastUpdate = Date.now();
  }

  function fail() {
    if (health.valid)
      health.stale = true;
  }

  function formatRate(bytes) {
    return health.rateValue(bytes) + " " + health.rateUnit(bytes);
  }

  function rateValue(bytes) {
    if (!isFinite(bytes) || bytes <= 0)
      return "0";
    if (bytes < 1048576)
      return (bytes / 1024).toFixed(1);
    return (bytes / 1048576).toFixed(1);
  }

  function rateUnit(bytes) {
    if (!isFinite(bytes) || bytes < 1024)
      return "B/s";
    if (bytes < 1048576)
      return "kB/s";
    return "MB/s";
  }

  function formatGib(value) {
    return (Number(value) || 0).toFixed(1);
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: sampler.running = true
  }

  Process {
    id: sampler
    command: [Runtime.healthScript, Runtime.sensorPath]

    stdout: StdioCollector {
      onStreamFinished: health.apply(text)
    }

    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0)
        health.fail();
    }
  }
}
