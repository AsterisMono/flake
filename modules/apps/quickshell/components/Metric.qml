import QtQuick
import QtQuick.Layouts
import qs

// One bar reading: an outline icon, its value, and an optional quiet unit.
//
// The value and unit share one run, at one size, separated by the mono font's
// own space, so they land on one baseline at any output scale and the line box
// matches plain bar text. A thin space here used to fall back to another font
// (FiraCode has no U+2009), which made this line box taller and dropped the
// reading below the volume; the unit is told apart by colour instead.
RowLayout {
  id: control

  property string name: ""
  property string value: ""
  property string unit: ""
  property color color: Theme.muted
  property color iconColor: Theme.dim
  property real iconSize: Theme.iconSize

  // Units that hang off the number (%, °C) are set flush; word-like units
  // (kB/s) keep one space.
  readonly property bool attachedUnit: control.unit !== ""
    && (control.unit.charAt(0) === "%" || control.unit.charAt(0) === "°")

  spacing: Theme.space1

  Icon {
    Layout.alignment: Qt.AlignVCenter
    visible: control.name !== ""
    name: control.name
    color: control.iconColor
    size: control.iconSize
  }

  Text {
    id: reading

    Layout.alignment: Qt.AlignVCenter
    textFormat: Text.StyledText
    text: control.unit === ""
      ? "<font color=\"" + control.color + "\">" + control.value + "</font>"
      : "<font color=\"" + control.color + "\">" + control.value + "</font>"
        + (control.attachedUnit ? "" : " ")
        + "<font color=\"" + Theme.dim + "\">" + control.unit + "</font>"
    font.family: Theme.mono
    font.pixelSize: Theme.fontBody
  }
}
