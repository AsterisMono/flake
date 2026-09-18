import QtQuick
import qs

Rectangle {
  id: frame

  default property alias content: column.data
  property int padding: Theme.panelPadding
  property int panelWidth: Theme.popupWidth
  property int maxHeight: 600

  implicitWidth: panelWidth
  implicitHeight: Math.min(column.implicitHeight + padding * 2, maxHeight)
  color: Theme.glass
  border.width: 1
  border.color: Theme.edge
  radius: Theme.radius

  Flickable {
    id: flick
    anchors.fill: parent
    anchors.margins: frame.padding
    contentWidth: width
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: column
      width: flick.width
      spacing: Theme.space3
    }
  }
}
