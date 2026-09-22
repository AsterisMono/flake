pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen backlight. Reading and writing both go through brightnessctl's
// default device, which is the same device the compositor's XF86MonBrightness
// keys drive: the popup, the keys and the OSD can never disagree about which
// backlight they mean. brightnessctl needs no elevated process here; when the
// sysfs file is not writable it falls back to logind's SetBrightness for the
// session the shell runs in.
Singleton {
  id: brightness

  // What the machine reports. `available` is false until a read succeeds, so a
  // machine with no backlight simply has no brightness entry to show.
  property bool valid: false
  property string device: ""
  property string deviceClass: ""
  property int current: 0
  property int maximum: 0

  // The value the user last asked for, in the machine's own units, held only
  // until the write carrying it has run. A control reads it so a drag stays
  // smooth between writes; the OSD reads `current` instead, so a write the
  // backlight rejected cannot be presented as the machine's state.
  property int requested: -1

  // Set when the backlight refused a write, so the popup can say so instead of
  // presenting the requested value as the machine's state.
  property bool failed: false
  // The last value requested while a write was still running.
  property int queued: -1

  readonly property bool available: brightness.valid && brightness.maximum > 0
  // The machine's own reading.
  readonly property real percent: brightness.available ? (brightness.current / brightness.maximum) * 100 : 0
  // What a control should show: the value in flight, or the machine's.
  readonly property int shown: brightness.requested >= 0 ? brightness.requested : brightness.current
  readonly property real shownPercent: brightness.available ? (brightness.shown / brightness.maximum) * 100 : 0

  // The file brightnessctl reads and writes for the device it selected. It is
  // the same file the poll below reads, reached without starting a process,
  // which is what makes the reading event driven.
  readonly property string readingPath: {
    if (brightness.device === "" || brightness.deviceClass === "")
      return "";
    return "/sys/class/" + brightness.deviceClass + "/" + brightness.device + "/brightness";
  }

  // Three icon steps, in the order the palette's sun glyphs brighten.
  readonly property string indicatorIcon: brightness.percent >= 67 ? "brightnessHigh" : brightness.percent >= 34 ? "brightnessMedium" : "brightnessLow"

  function refresh() {
    if (!reader.running)
      reader.running = true;
  }

  function apply(text) {
    const fields = String(text).trim().split("\n")[0].split(",");
    if (fields.length < 5) {
      brightness.valid = false;
      return;
    }

    brightness.device = fields[0];
    brightness.deviceClass = fields[1];
    brightness.current = Number(fields[2]) || 0;
    brightness.maximum = Number(fields[4]) || 0;
    brightness.valid = brightness.maximum > 0;
  }

  // A reading straight from the backlight file. It carries no maximum, so a
  // value arriving before the first brightnessctl read cannot make the device
  // available on its own; the poll that follows the write supplies that.
  function applyLevel(text) {
    const value = Number(String(text).trim());
    if (!isFinite(value) || value < 0) {
      // A read failure means the device is gone, not that brightness is zero.
      brightness.valid = false;
      return;
    }

    brightness.current = Math.round(value);
    brightness.valid = brightness.maximum > 0;
  }

  // The requested value is shown immediately and corrected by the read that
  // follows the write, so a rejected change falls back to the brightness the
  // machine actually has rather than staying on screen.
  function setPercent(value) {
    if (!brightness.available)
      return;

    const target = Math.round(Math.max(0, Math.min(100, value)));
    brightness.requested = Math.round(brightness.maximum * target / 100);
    brightness.write(target);
  }

  // Writes are serialized: a wheel or a drag can arrive faster than
  // brightnessctl exits, and only the last requested value has to land.
  function write(target) {
    if (writer.running) {
      brightness.queued = target;
      return;
    }

    brightness.failed = false;
    writer.command = [Runtime.brightnessctl, "--quiet", "set", target + "%"];
    writer.running = true;
  }

  Timer {
    // Device discovery and reconciliation. The watch above reports every change
    // to a device the shell has already found; this is what finds the device,
    // notices that it was replaced, and covers an event a busy session dropped.
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: brightness.refresh()
  }

  // The backlight file changes the instant any writer touches it, including
  // logind answering the compositor's brightness keys, so a change reaches the
  // shell without waiting for the next poll. The content is re-read explicitly:
  // a watch reports that the file changed, not what it now says.
  FileView {
    id: watcher

    path: brightness.readingPath
    watchChanges: brightness.readingPath !== ""
    printErrors: false

    onFileChanged: watcher.reload()

    onLoaded: brightness.applyLevel(watcher.text())

    onLoadFailed: {
      // An empty path is the state before the first poll has named a device.
      if (brightness.readingPath !== "")
        brightness.valid = false;
    }
  }

  Process {
    id: reader
    command: [Runtime.brightnessctl, "-m", "info"]

    stdout: StdioCollector {
      onStreamFinished: brightness.apply(text)
    }

    onExited: function(exitCode, exitStatus) {
      // A read failure means the device is gone, not that brightness is zero.
      if (exitCode !== 0)
        brightness.valid = false;
    }
  }

  Process {
    id: writer

    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0)
        brightness.failed = true;

      if (brightness.queued >= 0) {
        const next = brightness.queued;
        brightness.queued = -1;
        brightness.write(next);
        return;
      }

      // The write has run, so the value it carried has done its job. Everything
      // from here reports the machine's own reading again, whether or not the
      // write was accepted.
      brightness.requested = -1;
      brightness.refresh();
    }
  }
}
