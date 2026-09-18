pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// waycat owns the animation and its CPU-load pacing. One process serves every
// output; the bar only renders the current frame.
Singleton {
  id: catFrames

  property string frame: ""

  Process {
    id: waycat
    running: true
    command: [Runtime.waycat]

    stdout: SplitParser {
      onRead: function(line) {
        if (line.length > 0)
          catFrames.frame = line;
      }
    }

    onExited: restart.restart()
  }

  Timer {
    id: restart
    interval: 2000
    onTriggered: waycat.running = true
  }
}
