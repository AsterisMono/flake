import QtQuick
import qs

Rectangle {
  id: frame

  default property alias content: column.data
  property int padding: Theme.panelPadding

  implicitWidth: Theme.popupWidth
  implicitHeight: column.implicitHeight + padding * 2
  color: Theme.glass
  border.width: 1
  border.color: Theme.edge
  radius: Theme.radius

  Column {
    id: column
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: frame.padding
    spacing: Theme.space3
  }
}
