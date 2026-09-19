import QtQuick
import qs

Item {
  id: control

  required property var windowData

  signal activated()
  signal closed()

  width: parent ? parent.width : implicitWidth
  implicitHeight: 30

  Rectangle {
    anchors.fill: parent
    radius: Theme.radius
    color: mouse.containsMouse ? Theme.hover : "transparent"
  }

  Rectangle {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 2
    color: control.windowData.focused ? Theme.accent : "transparent"
  }

  Text {
    id: badge
    anchors.left: parent.left
    anchors.leftMargin: Theme.space2
    anchors.verticalCenter: parent.verticalCenter
    width: 17
    height: 17
    text: Theme.appMark(control.windowData.appId)
    color: Theme.muted
    font.family: Theme.mono
    font.pixelSize: Theme.fontBody
    font.weight: Font.Medium
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  Text {
    id: workspace
    anchors.right: parent.right
    anchors.rightMargin: Theme.space2
    anchors.verticalCenter: parent.verticalCenter
    text: control.windowData.workspace
    color: Theme.muted
    font.family: Theme.mono
    font.pixelSize: Theme.fontTiny
  }

  Text {
    anchors.left: badge.right
    anchors.leftMargin: Theme.space2
    anchors.right: workspace.left
    anchors.rightMargin: Theme.space2
    anchors.verticalCenter: parent.verticalCenter
    text: control.windowData.title
    color: control.windowData.focused ? Theme.text : Theme.muted
    font.family: Theme.mono
    font.pixelSize: Theme.fontSmall
    elide: Text.ElideRight
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

    onClicked: function(event) {
      if (event.button === Qt.MiddleButton)
        control.closed();
      else
        control.activated();
    }
  }
}
