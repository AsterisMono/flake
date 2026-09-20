import QtQuick
import QtQuick.Layouts
import qs

Item {
  id: control

  property string text: ""
  property string icon: ""
  property bool selected: false
  property int contentPadding: Theme.space3

  signal clicked()

  readonly property bool hovered: mouse.containsMouse && control.enabled

  implicitWidth: Math.max(88, contentRow.implicitWidth + control.contentPadding * 2)
  implicitHeight: Math.max(Theme.space4 * 2, contentRow.implicitHeight + Theme.space2 * 2)
  opacity: enabled ? 1 : 0.4
  activeFocusOnTab: true

  Rectangle {
    anchors.fill: parent
    radius: Theme.space1
    color: control.selected ? Theme.selected : (mouse.pressed && control.enabled ? Theme.fillPressed : (control.hovered ? Theme.fillHover : Theme.fill))
    border.width: 1
    border.color: control.selected || control.activeFocus ? Theme.accent : (control.hovered ? Theme.borderHover : Theme.border)

    Behavior on color {
      ColorAnimation {
        duration: Theme.motion
      }
    }

    Behavior on border.color {
      ColorAnimation {
        duration: Theme.motion
      }
    }
  }

  RowLayout {
    id: contentRow
    anchors.centerIn: parent
    spacing: Theme.space2
    width: Math.max(0, control.width - control.contentPadding * 2)

    Icon {
      Layout.alignment: Qt.AlignBaseline
      visible: control.icon !== ""
      name: control.icon
      color: control.selected ? Theme.accent : Theme.muted
      size: Theme.iconSize
    }

    Text {
      Layout.alignment: Qt.AlignBaseline
      Layout.fillWidth: true
      text: control.text
      color: Theme.text
      font.family: Theme.mono
      font.pixelSize: Theme.fontBody
      elide: Text.ElideRight
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    preventStealing: true
    enabled: control.enabled
    onClicked: control.clicked()
  }
}
