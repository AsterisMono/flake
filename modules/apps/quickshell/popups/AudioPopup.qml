import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components

PopupFrame {
  id: popup

  padding: Theme.panelPadding

  PopupHeader {
    title: "Audio output"
    note: Audio.available ? (Audio.sinkName || "Current output") : "No audio output is available."
    onCloseRequested: ShellState.close()
  }

  RowLayout {
    width: parent.width
    spacing: Theme.space2

    Icon {
      Layout.alignment: Qt.AlignVCenter
      name: Audio.muted ? "muted" : "volume"
      color: Audio.muted ? Theme.muted : Theme.muted
      size: Theme.iconMedium
    }

    Text {
      Layout.fillWidth: true
      text: !Audio.available ? "unavailable" : (Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%")
      color: Theme.text
      font.family: Theme.mono
      font.pixelSize: Theme.fontBody
    }

    ActionButton {
      icon: Audio.indicatorIcon
      text: Audio.muted ? "Unmute" : "Mute"
      enabled: Audio.available
      onClicked: Audio.toggleMute()
    }
  }

  MeterSlider {
    width: parent.width
    from: 0
    to: 1.5
    value: Audio.volume
    enabled: Audio.available
    live: true
    onMoved: Audio.setVolume(value)
  }

  Text {
    width: parent.width
    text: "Click for controls · middle-click mutes · scroll changes by 1%"
    color: Theme.muted
    font.family: Theme.reading
    font.pixelSize: Theme.fontTiny
    wrapMode: Text.Wrap
  }

  Text {
    width: parent.width
    text: "Output device"
    color: Theme.muted
    font.family: Theme.mono
    font.pixelSize: Theme.fontTiny
    font.letterSpacing: 1.1
  }

  Repeater {
    model: Audio.sinks

    delegate: ActionButton {
      required property var modelData
      width: parent ? parent.width : implicitWidth
      text: modelData.description || modelData.nickname || modelData.name
      icon: modelData === Audio.sink ? "check" : "volume"
      selected: modelData === Audio.sink
      onClicked: Audio.setDefaultSink(modelData)
    }
  }

  ActionButton {
    icon: "sliders"
    text: "Open mixer ↗"
    onClicked: {
      Quickshell.execDetached([Runtime.pavucontrol]);
      ShellState.close();
    }
  }
}
