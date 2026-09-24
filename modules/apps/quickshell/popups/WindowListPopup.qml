import QtQuick
import qs
import qs.components

ScrollFrame {
  id: popup

  PopupHeader {
    kicker: "All outputs"
    title: "All windows · " + Desktop.windows.length
    onCloseRequested: ShellState.close()
  }

  Repeater {
    model: Desktop.windows

    delegate: TaskRow {
      required property var modelData
      windowData: modelData
      onActivated: Desktop.activateWindow(modelData.id)
      onClosed: Desktop.closeWindow(modelData.id)
    }
  }
}
