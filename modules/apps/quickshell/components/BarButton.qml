import QtQuick
import QtQuick.Layouts
import qs

Item {
  id: control

  default property alias content: contentRow.data
  property alias row: contentRow
  property bool active: false
  property bool attention: false
  property bool interactive: true
  property bool leadingDivider: false
  // Room around the content, so the hover highlight is not glued to the icon.
  property int padding: Theme.space2
  property int gap: Theme.space2

  signal clicked(var mouse)
  signal middleClicked(var mouse)
  signal rightClicked(var mouse)
  signal wheeled(real delta, bool horizontal)

  implicitWidth: contentRow.implicitWidth + padding * 2
  implicitHeight: Theme.barHeight

  Rectangle {
    anchors.fill: parent
    color: control.active ? Theme.selected : (control.attention ? Theme.attentionFill : (mouse.containsMouse && control.interactive ? Theme.hover : "transparent"))
    Behavior on color {
      ColorAnimation {
        duration: Theme.motion
      }
    }
  }

  Rectangle {
    visible: control.leadingDivider
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 1
    color: Theme.separator
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 2
    color: control.attention ? Theme.attention : (control.active ? Theme.accent : "transparent")
  }

  RowLayout {
    id: contentRow
    anchors.centerIn: parent
    spacing: control.gap
    width: Math.max(0, control.width - control.padding * 2)
    height: control.height
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: control.interactive
    preventStealing: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

    onClicked: function(event) {
      if (event.button === Qt.MiddleButton)
        control.middleClicked(event);
      else if (event.button === Qt.RightButton)
        control.rightClicked(event);
      else
        control.clicked(event);
    }

    onWheel: function(event) {
      control.wheeled(event.angleDelta.y, Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y));
    }
  }
}
