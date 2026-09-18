import QtQuick
import qs
import qs.components

PopupFrame {
  id: popup

  PopupHeader {
    title: "Your desktop"
    onCloseRequested: ShellState.close()
  }

  Repeater {
    model: [
      { "label": "Host", "value": Runtime.hostName },
      { "label": "NixOS", "value": Runtime.nixosVersion },
      { "label": "Quickshell", "value": Runtime.quickshellVersion },
      { "label": "Sway", "value": Runtime.swayVersion }
    ]

    delegate: Row {
      required property var modelData
      width: popup.width - popup.padding * 2
      spacing: Theme.space3

      Text {
        width: 80
        text: modelData.label
        color: Theme.dim
        font.family: Theme.mono
        font.pixelSize: Theme.fontSmall
      }

      Text {
        width: Math.max(0, parent.width - 92)
        text: modelData.value
        color: Theme.muted
        font.family: Theme.mono
        font.pixelSize: Theme.fontSmall
        elide: Text.ElideRight
      }
    }
  }
}
