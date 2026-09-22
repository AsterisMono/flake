pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen backlight. Reading and writing both go through brightnessctl's
// default device, which is the same device the compositor's XF86MonBrightness
// keys drive: the bar, the popup and the keys can never disagree about which
// backlight they mean. brightnessctl needs no elevated process here; when the
// sysfs file is not writable it falls back to logind's SetBrightness for the
// session the shell runs in.
Singleton {
  id: brightness

  // Last reading. `available` is false until a read succeeds, so a machine
  // with no backlight simply has no brightness entry to show.
  property bool valid: false
  property string device: ""
  property int current: 0
  property int maximum: 0

  // Set when the backlight refused a write, so the popup can say so instead of
  // presenting the requested value as the machine's state.
  property bool failed: false
  // The last value requested while a write was still running.
  property int queued: -1

  readonly property bool available: brightness.valid && brightness.maximum > 0
  readonly property real percent: brightness.available ? (brightness.current / brightness.maximum) * 100 : 0

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
    brightness.current = Number(fields[2]) || 0;
    brightness.maximum = Number(fields[4]) || 0;
    brightness.valid = brightness.maximum > 0;
  }

  // The requested value is shown immediately and corrected by the read that
  // follows the write, so a rejected change falls back to the brightness the
  // machine actually has rather than staying on screen.
  function setPercent(value) {
    if (!brightness.available)
      return;

    const target = Math.round(Math.max(0, Math.min(100, value)));
    brightness.current = Math.round(brightness.maximum * target / 100);
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
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: brightness.refresh()
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

      brightness.refresh();
    }
  }
}
