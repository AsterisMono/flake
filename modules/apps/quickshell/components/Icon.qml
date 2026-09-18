import QtQuick
import QtQuick.Layouts
import qs

// One outline glyph from the Nerd Font.
//
// Every icon in the shell is a single glyph with the same family, the same
// centring and a size taken from the theme's icon scale. Keeping the pieces
// that make an icon in one place is what stops call sites from drifting into
// their own sizes and alignments, and it makes the layout declarations
// (`Layout.alignment`, `anchors`) at the call site part of the icon.
Text {
  id: control

  property string name: ""
  property int size: Theme.iconSize

  text: Icons.glyph(control.name)
  color: Theme.muted
  font.family: Theme.mono
  font.pixelSize: size
  horizontalAlignment: Text.AlignHCenter
  verticalAlignment: Text.AlignVCenter
  width: size
  height: size
  Layout.preferredWidth: size
  Layout.preferredHeight: size
}
