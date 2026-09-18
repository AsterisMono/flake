import QtQuick
import qs

Item {
  id: header

  property string kicker: ""
  property string title: ""
  property string note: ""
  property string titleFamily: Theme.mono
  property int titleSize: Theme.fontTitle
  property int titleWeight: Font.Normal

  signal closeRequested()

  // A plain Column does not stretch its children, so the width has to come
  // from the parent explicitly. Without it the inner Column stays 0 wide and
  // reports an implicitHeight of 0, which collapses the whole header.
  width: parent ? parent.width : implicitWidth
  implicitHeight: column.implicitHeight

  Column {
    id: column
    width: parent.width
    spacing: Theme.space2

    Text {
      visible: header.kicker !== ""
      text: header.kicker
      color: Theme.dim
      font.family: Theme.mono
      font.pixelSize: Theme.fontTiny
      font.letterSpacing: 1.2
      font.capitalization: Font.AllUppercase
    }

    Item {
      width: parent.width
      height: Math.max(titleText.implicitHeight, closeButton.implicitHeight)

      Text {
        id: titleText
        anchors.left: parent.left
        anchors.right: closeButton.left
        anchors.rightMargin: Theme.space2
        anchors.verticalCenter: parent.verticalCenter
        text: header.title
        color: Theme.text
        font.family: header.titleFamily
        font.pixelSize: header.titleSize
        font.weight: header.titleWeight
        elide: Text.ElideRight
      }

      IconButton {
        id: closeButton
        anchors.right: parent.right
        anchors.top: parent.top
        name: "close"
        onClicked: header.closeRequested()
      }
    }

    Text {
      visible: header.note !== ""
      width: parent.width
      text: header.note
      color: Theme.muted
      font.family: Theme.reading
      font.pixelSize: Theme.fontSmall
      wrapMode: Text.Wrap
      lineHeight: 1.35
    }
  }
}
