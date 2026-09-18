import QtQuick
import qs

Text {
  id: control

  property int size: 19

  text: CatFrames.frame !== "" ? CatFrames.frame : " "
  color: Theme.muted
  font.family: "polycat"
  font.pixelSize: size
  horizontalAlignment: Text.AlignHCenter
  verticalAlignment: Text.AlignVCenter
}
