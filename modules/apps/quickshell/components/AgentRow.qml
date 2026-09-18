import QtQuick
import QtQuick.Layouts
import qs
import qs.work

// One row of the Work in flight panel: a plain list entry, not a card and not
// a row of buttons. The whole row opens the agent; there is no other control.
Item {
  id: control

  required property var row
  // The last row in the panel needs no rule: the footer already draws one.
  property bool divider: true

  readonly property bool actionable: control.row.openable

  width: parent ? parent.width : 0
  // Equal padding above and below the row's lines, so the hover highlight (the
  // whole row) sits around the text evenly.
  implicitHeight: content.implicitHeight + Theme.space3 * 2

  Rectangle {
    anchors.fill: parent
    color: mouse.containsMouse && control.actionable ? Theme.hover : "transparent"
  }

  Rectangle {
    visible: control.divider
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.leftMargin: Theme.panelPadding
    anchors.rightMargin: Theme.panelPadding
    height: 1
    color: Theme.separator
  }

  Column {
    id: content

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.leftMargin: Theme.panelPadding
    anchors.rightMargin: Theme.panelPadding
    anchors.topMargin: Theme.space3
    spacing: Theme.space2

    Item {
      width: parent.width
      implicitHeight: Math.max(titleText.implicitHeight, stateRow.implicitHeight)

      Text {
        id: titleText
        anchors.left: parent.left
        anchors.right: stateRow.left
        anchors.rightMargin: Theme.space2
        anchors.top: parent.top
        text: control.row.title
        color: Theme.text
        font.family: Theme.reading
        font.pixelSize: Theme.fontTitle
        font.weight: Font.Medium
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
      }

      RowLayout {
        id: stateRow
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.space1

        Icon {
          Layout.alignment: Qt.AlignVCenter
          visible: control.row.stateIcon !== ""
          name: control.row.stateIcon
          color: control.row.stateColor
          size: Theme.iconSmall
        }

        Text {
          Layout.alignment: Qt.AlignVCenter
          text: control.row.stateLabel
          color: control.row.stateColor
          font.family: Theme.mono
          font.pixelSize: Theme.fontTiny
        }
      }
    }

    Text {
      visible: control.row.context !== ""
      width: parent.width
      text: control.row.context
      color: Theme.dim
      font.family: Theme.mono
      font.pixelSize: Theme.fontMicro
      elide: Text.ElideRight
    }

    Text {
      visible: control.row.timeText !== ""
      width: parent.width
      text: control.row.timeText
      color: Theme.dim
      font.family: Theme.mono
      font.pixelSize: Theme.fontMicro
      elide: Text.ElideRight
    }

    Text {
      visible: control.row.note !== ""
      width: parent.width
      text: control.row.note
      color: Theme.muted
      font.family: Theme.reading
      font.pixelSize: Theme.fontBody
      lineHeight: 1.4
      wrapMode: Text.Wrap
    }
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: control.actionable
    cursorShape: control.actionable ? Qt.PointingHandCursor : Qt.ArrowCursor
    enabled: control.actionable
    onClicked: WorkInFlight.open(control.row)
  }
}
