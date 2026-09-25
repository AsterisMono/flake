import QtQuick
import qs

// One quota reading: what the limit belongs to, how much of it is left, and
// when it refills. The reading is the caller's — a rate limit window, a credit
// allowance or a fixture all draw the same way — and the row is the one place
// the bar's geometry is stated, so every quota on a panel reads at one scale.
Item {
  id: control

  // What the limit applies to, already including its window ("Codex 1w").
  property string label: ""
  // Share of the limit still available, 0–100.
  property real percent: 0
  // When the limit refills, set beside the label, or why it cannot be read.
  property string note: ""

  width: parent ? parent.width : 0
  implicitHeight: column.implicitHeight

  Column {
    id: column

    width: parent.width
    spacing: Theme.space2

    Item {
      width: parent.width
      implicitHeight: Math.max(labelText.implicitHeight, percentText.implicitHeight)

      // The label yields to the note, which keeps its own width and one gap on
      // either side, so a long title elides rather than pushing the reset out
      // of the row or closing on the percentage.
      Text {
        id: labelText

        anchors.left: parent.left
        width: Math.max(0, Math.min(implicitWidth,
          percentText.x - Theme.space2 - (noteText.visible ? noteText.width + Theme.space2 : 0)))
        text: control.label
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: Theme.text
        font.family: Theme.mono
        font.pixelSize: Theme.fontBody
        font.weight: Font.Medium
      }

      Text {
        id: noteText

        anchors.left: labelText.right
        anchors.leftMargin: visible ? Theme.space2 : 0
        anchors.baseline: labelText.baseline
        visible: text !== ""
        text: control.note
        textFormat: Text.PlainText
        color: Theme.muted
        font.family: Theme.mono
        font.pixelSize: Theme.fontMicro
      }

      Text {
        id: percentText

        anchors.right: parent.right
        text: Math.round(control.percent) + "% left"
        color: Theme.text
        font.family: Theme.mono
        font.pixelSize: Theme.fontBody
        font.weight: Font.Medium
      }
    }

    Rectangle {
      width: parent.width
      height: 4
      radius: height / 2
      color: Theme.track
      clip: true

      Rectangle {
        width: parent.width * Math.max(0, Math.min(100, control.percent)) / 100
        height: parent.height
        radius: parent.radius
        color: Theme.accent
      }
    }
  }
}
