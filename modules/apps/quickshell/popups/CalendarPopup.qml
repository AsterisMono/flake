import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components

PopupFrame {
  id: popup

  property int monthOffset: 0

  implicitHeight: width

  readonly property var month: {
    const now = clock.date;
    return new Date(now.getFullYear(), now.getMonth() + popup.monthOffset, 1);
  }

  readonly property int leadingBlanks: (popup.month.getDay() + 6) % 7
  readonly property int daysInMonth: new Date(popup.month.getFullYear(), popup.month.getMonth() + 1, 0).getDate()
  readonly property int cellWidth: Math.floor((popup.width - popup.padding * 2) / 7)
  readonly property int rows: Math.max(1, Math.ceil((leadingBlanks + daysInMonth) / 7))
  readonly property real gridHeight: Math.max(rows * 24,
    popup.width - popup.padding * 2
      - headerRow.implicitHeight - todayText.implicitHeight - weekdayRow.implicitHeight
      - todayButton.implicitHeight - Theme.space3 * 4)
  readonly property real cellHeight: gridHeight / rows

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  RowLayout {
    id: headerRow
    width: parent.width

    IconButton {
      text: "‹"
      onClicked: popup.monthOffset--
    }

    Text {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      text: Qt.formatDateTime(popup.month, "MMMM yyyy")
      color: Theme.text
      font.family: Theme.mono
      font.pixelSize: Theme.fontTitle
    }

    IconButton {
      text: "›"
      onClicked: popup.monthOffset++
    }
  }

  Text {
    id: todayText
    width: parent.width
    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
    color: Theme.muted
    font.family: Theme.reading
    font.pixelSize: Theme.fontSmall
  }

  Row {
    id: weekdayRow
    width: parent.width
    spacing: 0

    Repeater {
      model: ["M", "T", "W", "T", "F", "S", "S"]

      delegate: Text {
        required property var modelData
        width: popup.cellWidth
        horizontalAlignment: Text.AlignHCenter
        text: modelData
        color: Theme.muted
        font.family: Theme.mono
        font.pixelSize: Theme.fontTiny
      }
    }
  }

  Grid {
    width: parent.width
    columns: 7
    spacing: 0

    Repeater {
      model: popup.leadingBlanks

      delegate: Item {
        width: popup.cellWidth
        height: popup.cellHeight
      }
    }

    Repeater {
      model: popup.daysInMonth

      delegate: Item {
        required property int index

        readonly property int day: index + 1
        readonly property bool today: popup.monthOffset === 0
          && popup.month.getFullYear() === clock.date.getFullYear()
          && popup.month.getMonth() === clock.date.getMonth()
          && day === clock.date.getDate()

        width: popup.cellWidth
        height: popup.cellHeight

        Rectangle {
          anchors.centerIn: parent
          width: 22
          height: 22
          radius: 11
          color: today ? Theme.selected : "transparent"
          border.width: today ? 1 : 0
          border.color: Theme.accent
        }

        Text {
          anchors.centerIn: parent
          text: day
          color: today ? Theme.text : Theme.muted
          font.family: Theme.mono
          font.pixelSize: Theme.fontSmall
        }
      }
    }
  }

  ActionButton {
    id: todayButton
    icon: "calendar"
    text: "Back to today"
    enabled: popup.monthOffset !== 0
    onClicked: popup.monthOffset = 0
  }
}
