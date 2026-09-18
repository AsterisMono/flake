import QtQuick
import qs

Item {
  id: control

  property string name: "close"
  property string text: ""
  property color iconColor: Theme.muted
  property int size: 22
  property real iconSize: Math.round(size * 0.6)

  signal clicked(var mouse)

  implicitWidth: size
  implicitHeight: size

  Rectangle {
    anchors.fill: parent
    radius: Theme.radius
    color: mouse.containsMouse ? Theme.hover : "transparent"
  }

  Icon {
    visible: control.text === ""
    anchors.centerIn: parent
    name: control.name
    color: control.iconColor
    size: control.iconSize
  }

  Text {
    visible: control.text !== ""
    anchors.centerIn: parent
    text: control.text
    color: control.iconColor
    font.family: Theme.mono
    font.pixelSize: Math.round(control.size * 0.7)
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    preventStealing: true
    onClicked: function(event) {
      control.clicked(event);
    }
  }
}
