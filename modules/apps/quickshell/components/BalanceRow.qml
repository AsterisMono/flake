import QtQuick
import QtQuick.Layouts
import qs

// One account balance: what the balance belongs to on the left, the amount on
// the right. A reading that has not arrived yet reads "loading", and a failed
// one reads "unavailable" in secondary text, so a quiet panel never looks like
// a zero balance.
RowLayout {
  id: control

  property string label: ""
  // The reading itself, meaningful only while `ok` is true.
  property string value: ""
  // Whether `value` is a usable reading, and whether one has arrived at all.
  property bool ok: true
  property bool loaded: true

  width: parent ? parent.width : 0
  // One row height for every balance, so the column keeps one pitch whether a
  // source answers or not.
  implicitHeight: Theme.space5 + Theme.space1
  spacing: Theme.space2

  Text {
    Layout.alignment: Qt.AlignVCenter
    text: control.label
    textFormat: Text.PlainText
    color: Theme.text
    font.family: Theme.mono
    font.pixelSize: Theme.fontSmall
  }

  Item {
    Layout.fillWidth: true
  }

  Text {
    Layout.alignment: Qt.AlignVCenter
    text: control.ok ? control.value : (control.loaded ? "unavailable" : "loading")
    textFormat: Text.PlainText
    color: control.ok ? Theme.text : Theme.muted
    font.family: Theme.mono
    font.pixelSize: Theme.fontSmall
  }
}
