import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.components
import qs.work

PanelWindow {
  id: bar

  readonly property bool narrow: bar.width < 1000

  anchors.bottom: true
  anchors.left: true
  anchors.right: true
  implicitHeight: Theme.barHeight
  exclusiveZone: Theme.barHeight
  color: "transparent"
  WlrLayershell.namespace: "quickshell-bar-bottom"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Rectangle {
    anchors.fill: parent
    color: Theme.barGlass(Desktop.workspaceOccupied(bar.screen))

    Behavior on color {
      ColorAnimation {
        duration: Theme.motion
      }
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: 1
      color: Theme.edge
    }
  }

  RowLayout {
    id: workspaces
    anchors.left: parent.left
    anchors.leftMargin: Theme.space2
    anchors.verticalCenter: parent.verticalCenter
    spacing: 0

    Repeater {
      model: Desktop.workspaces

      delegate: BarButton {
        required property var modelData
        padding: 0
        Layout.minimumWidth: 38
        Layout.preferredWidth: 38
        Layout.maximumWidth: 38
        Layout.fillHeight: true
        active: modelData.focused || modelData.active
        attention: modelData.urgent
        onClicked: Desktop.activateWorkspace(modelData)
        onWheeled: function(delta, horizontal) {
          if (!horizontal)
            Desktop.switchWorkspace(modelData, delta);
        }

        Text {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          text: modelData.name
          color: modelData.urgent ? Theme.attention : (modelData.focused ? Theme.text : Theme.muted)
          font.family: Theme.mono
          font.pixelSize: Theme.fontBody
          elide: Text.ElideRight
        }
      }
    }
  }

  Rectangle {
    anchors.left: workspaces.right
    anchors.leftMargin: Theme.space2
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 1
    color: Theme.separator
  }

  Item {
    id: taskArea
    anchors.left: workspaces.right
    anchors.leftMargin: Theme.space2
    anchors.right: overflowButton.left
    anchors.rightMargin: Theme.space1
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    clip: true

    readonly property int capacity: Math.max(1, Math.floor(width / 140))
    readonly property var visibleTasks: Desktop.visibleWindows(capacity)
    readonly property real taskWidth: visibleTasks.length > 0 ? Math.max(140, Math.min(240, width / visibleTasks.length)) : 240

    RowLayout {
      anchors.fill: parent
      spacing: 0

      Repeater {
        model: taskArea.visibleTasks

        delegate: BarButton {
          required property var modelData
          padding: Theme.space3
          gap: Theme.space2
          Layout.minimumWidth: 120
          Layout.preferredWidth: taskArea.taskWidth
          Layout.maximumWidth: 260
          Layout.fillHeight: true
          active: modelData.focused
          attention: modelData.urgent
          onClicked: Desktop.activateWindow(modelData.id)
          onMiddleClicked: Desktop.closeWindow(modelData.id)

          Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 17
            Layout.preferredHeight: 17
            text: Theme.appMark(modelData.appId)
            color: Theme.muted
            font.family: Theme.mono
            font.pixelSize: Theme.fontBody
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }

          Text {
            Layout.fillWidth: true
            text: modelData.title
            color: modelData.urgent ? Theme.attention : (modelData.focused ? Theme.text : Theme.muted)
            font.family: Theme.mono
            font.pixelSize: Theme.fontBody
            elide: Text.ElideRight
          }

          Text {
            text: modelData.workspace
            color: Theme.muted
            font.family: Theme.mono
            font.pixelSize: Theme.fontMicro
          }
        }
      }

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
      }
    }
  }

  BarButton {
    id: overflowButton
    visible: Desktop.windows.length > taskArea.capacity
    anchors.right: workSlot.left
    anchors.rightMargin: Theme.space2
    anchors.verticalCenter: parent.verticalCenter
    width: implicitWidth
    padding: Theme.space2
    active: ShellState.kind === "windows"
    onClicked: ShellState.toggle("windows", bar.screen, Theme.centerX(overflowButton))

    Text {
      text: "…"
      color: Theme.muted
      font.family: Theme.mono
      font.pixelSize: Theme.fontBody
    }
  }

  // Work in flight: one compact end section, not one widget per agent. It is
  // removed entirely while there is nothing to return to.
  Item {
    id: workSlot

    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    // The section is only as wide as its own summary: one line of counts.
    readonly property int reserve: workButton.implicitWidth
    width: WorkSummary.visible ? reserve : 0
    clip: true

    BarButton {
      id: workButton

      anchors.fill: parent
      padding: Theme.space3
      gap: Theme.space2
      active: ShellState.kind === "work"
      attention: WorkSummary.needsYou
      enabled: WorkSummary.visible
      leadingDivider: true
      onClicked: ShellState.toggle("work", bar.screen, Theme.centerX(workButton))

      // Each count carries its own state icon, so the button needs no separate
      // leading glyph. Type and glyph size come from the same tokens the top
      // bar uses.
      RowLayout {
        Layout.alignment: Qt.AlignVCenter
        spacing: Theme.space1

        Repeater {
          model: bar.narrow ? WorkSummary.compactParts : WorkSummary.fullParts

          delegate: RowLayout {
            required property var modelData
            required property int index

            spacing: Theme.space1

            Text {
              Layout.alignment: Qt.AlignBaseline
              visible: index > 0
              text: "·"
              color: Theme.text
              font.family: Theme.mono
              font.pixelSize: Theme.fontBody
            }

            Icon {
              Layout.alignment: Qt.AlignVCenter
              name: modelData.icon
              color: modelData.color
              size: Theme.iconSize
            }

            Text {
              Layout.alignment: Qt.AlignBaseline
              text: modelData.text
              color: modelData.color
              font.family: Theme.mono
              font.pixelSize: Theme.fontBody
            }
          }
        }
      }
    }
  }
}
