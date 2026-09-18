import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components

Rectangle {
  id: center

  readonly property int padding: Theme.panelPadding

  implicitWidth: Theme.drawerWidth
  implicitHeight: 620
  color: Theme.glass
  border.width: 1
  border.color: Theme.edge

  SystemClock {
    id: clock
    precision: SystemClock.Hours
  }

  Column {
    anchors.fill: parent
    spacing: 0

    Item {
      id: headerBlock
      width: parent.width
      implicitHeight: headerColumn.implicitHeight + center.padding

      Column {
        id: headerColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: center.padding
        spacing: 0

        Text {
          width: parent.width
          text: Qt.formatDateTime(clock.date, "dddd, MMM d")
          color: Theme.dim
          font.family: Theme.mono
          font.pixelSize: Theme.fontMicro
          font.letterSpacing: 1.2
          font.capitalization: Font.AllUppercase
        }

        Item {
          width: parent.width
          implicitHeight: Math.max(titleRow.implicitHeight, headerClose.implicitHeight)

          RowLayout {
            id: titleRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space2

            Text {
              Layout.alignment: Qt.AlignBaseline
              text: "Notifications"
              color: Theme.text
              font.family: Theme.reading
              font.pixelSize: Theme.fontLarge
              font.weight: Font.Medium
            }

            Item {
              Layout.fillWidth: true
              Layout.fillHeight: true
            }

            IconButton {
              id: headerClose
              name: "close"
              onClicked: ShellState.close()
            }
          }
        }

        Item {
          width: parent.width
          implicitHeight: Theme.space3
        }

        RowLayout {
          width: parent.width
          spacing: Theme.space2

          ActionButton {
            Layout.fillWidth: true
            icon: Notices.dnd ? "bellOff" : "bell"
            text: "Do Not Disturb"
            selected: Notices.dnd
            onClicked: Notices.dnd = !Notices.dnd
          }

          ActionButton {
            icon: "trash"
            text: "Clear all"
            enabled: Notices.savedCount > 0
            onClicked: Notices.clearAll()
          }
        }

        Text {
          width: parent.width
          visible: Notices.dnd
          text: "Banners are paused. New notifications still arrive here, and critical alerts still appear."
          color: Theme.dim
          font.family: Theme.reading
          font.pixelSize: Theme.fontTiny
          wrapMode: Text.Wrap
        }

        Item {
          width: parent.width
          implicitHeight: Theme.space3
        }
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.separator
      }
    }

    Flickable {
      id: list
      width: parent.width
      height: Math.max(0, parent.height - headerBlock.implicitHeight)
      contentWidth: width
      contentHeight: listColumn.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: listColumn
        width: list.width
        spacing: 0

        Repeater {
          model: Notices.savedRecords

          delegate: NoticeRow {}
        }

        Item {
          visible: Notices.savedCount === 0
          width: listColumn.width
          height: 180

          Column {
            anchors.centerIn: parent
            spacing: Theme.space2

            Icon {
              anchors.horizontalCenter: parent.horizontalCenter
              name: "bell"
              color: Theme.dim
              size: Theme.iconLarge
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Nothing here for now."
              color: Theme.muted
              font.family: Theme.reading
              font.pixelSize: Theme.fontBody
            }
          }
        }
      }
    }

  }
}
