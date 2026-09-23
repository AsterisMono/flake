import QtQuick
import qs

Rectangle {
  id: frame

  default property alias content: column.data
  property alias headerContent: headerColumn.data
  property int padding: Theme.panelPadding
  property int panelWidth: Theme.popupWidth
  property int maxHeight: 600
  property int contentSpacing: Theme.space3

  implicitWidth: panelWidth
  implicitHeight: Math.min(headerColumn.implicitHeight + column.implicitHeight + padding * 2, maxHeight)
  color: Theme.glass
  border.width: 1
  border.color: Theme.edge
  radius: Theme.radius

  Column {
    id: headerColumn
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: frame.padding
    spacing: frame.contentSpacing
  }

  Flickable {
    id: flick
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: headerColumn.bottom
    anchors.bottom: parent.bottom
    anchors.leftMargin: frame.padding
    anchors.rightMargin: frame.padding
    anchors.bottomMargin: frame.padding
    contentWidth: width
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: column
      width: flick.width
      spacing: frame.contentSpacing
    }
  }
}
