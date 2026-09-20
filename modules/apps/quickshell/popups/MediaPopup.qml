import QtQuick
import QtQuick.Layouts
import qs
import qs.components

PopupFrame {
  id: popup

  readonly property var player: Media.player

  Component.onCompleted: Media.choose()

  PopupHeader {
    title: "Now playing"
    note: popup.player ? (popup.player.identity || "Media player") : "No media player is running."
    onCloseRequested: ShellState.close()
  }

  Item {
    visible: popup.player !== null
    width: parent.width
    height: 92

    Rectangle {
      id: artwork
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: 92
      height: 92
      color: Theme.fill
      border.width: 1
      border.color: Theme.edge

      Image {
        anchors.fill: parent
        anchors.margins: 1
        source: popup.player ? popup.player.trackArtUrl : ""
        fillMode: Image.PreserveAspectCrop
        cache: false
        visible: source !== ""
      }

      Icon {
        anchors.centerIn: parent
        visible: !popup.player || popup.player.trackArtUrl === ""
        name: "music"
        color: Theme.muted
        size: Theme.iconDisplay
      }
    }

    Column {
      anchors.left: artwork.right
      anchors.leftMargin: Theme.space3
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Theme.space1

      Text {
        width: parent.width
        text: popup.player ? (popup.player.trackTitle || "Unknown title") : ""
        color: Theme.text
        font.family: Theme.reading
        font.pixelSize: Theme.fontLarge
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        text: popup.player ? (popup.player.trackArtist || popup.player.trackAlbumArtist || "") : ""
        color: Theme.muted
        font.family: Theme.reading
        font.pixelSize: Theme.fontSmall
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        text: popup.player ? (popup.player.trackAlbum || "") : ""
        color: Theme.muted
        font.family: Theme.reading
        font.pixelSize: Theme.fontTiny
        elide: Text.ElideRight
      }
    }
  }

  Text {
    visible: popup.player === null
    width: parent.width
    text: "Nothing is playing.\nOpen a player and it will appear here."
    color: Theme.muted
    font.family: Theme.reading
    font.pixelSize: Theme.fontSmall
    lineHeight: 1.4
  }

  MeterSlider {
    visible: popup.player !== null && popup.player.positionSupported
    width: parent.width
    from: 0
    to: popup.player && popup.player.length > 0 ? popup.player.length : 1
    value: popup.player ? popup.player.position : 0
    enabled: popup.player !== null && popup.player.canSeek
    live: false
    onCommitted: Media.seek(value)
  }

  RowLayout {
    visible: popup.player !== null
    width: parent.width
    spacing: Theme.space2

    Text {
      Layout.fillWidth: true
      text: popup.player ? formatTime(popup.player.position) : "0:00"
      color: Theme.muted
      font.family: Theme.mono
      font.pixelSize: Theme.fontTiny
    }

    Text {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignRight
      text: popup.player ? formatTime(popup.player.length) : "0:00"
      color: Theme.muted
      font.family: Theme.mono
      font.pixelSize: Theme.fontTiny
    }
  }

  RowLayout {
    visible: popup.player !== null
    width: parent.width
    spacing: Theme.space2

    IconButton {
      text: "|◀"
      size: 30
      enabled: popup.player !== null && popup.player.canGoPrevious
      onClicked: Media.previous()
    }

    IconButton {
      name: popup.player && popup.player.isPlaying ? "pause" : "play"
      size: 34
      iconColor: Theme.text
      enabled: popup.player !== null && popup.player.canTogglePlaying
      onClicked: Media.toggle()
    }

    IconButton {
      text: "▶|"
      size: 30
      enabled: popup.player !== null && popup.player.canGoNext
      onClicked: Media.next()
    }
  }

  function formatTime(seconds) {
    if (!isFinite(seconds) || seconds <= 0)
      return "0:00";
    const total = Math.floor(seconds);
    const rest = total % 60;
    return Math.floor(total / 60) + ":" + (rest < 10 ? "0" : "") + rest;
  }
}
