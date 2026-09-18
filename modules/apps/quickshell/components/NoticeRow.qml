import QtQuick
import QtQuick.Layouts
import qs
import Quickshell.Services.Notifications

Item {
  id: card

  required property var modelData
  // Banners reuse this row: same content, a plate of its own, tighter padding
  // and no list separator.
  property bool banner: false

  readonly property var record: modelData
  // Content changes bump Notices.revision; re-reading through it keeps this
  // card alive (a rebuild here would cancel a click in progress).
  readonly property var live: (Notices.revision, record.live)
  readonly property string summary: live ? live.summary : record.summary
  readonly property string body: live ? live.body : record.body
  readonly property string appName: live ? live.appName : record.appName
  readonly property int urgency: (Notices.revision, live ? live.urgency : record.urgency)
  readonly property var actions: (Notices.revision, live ? live.actions : [])

  width: parent ? parent.width : 0
  implicitHeight: contentColumn.implicitHeight + (card.banner ? Theme.space2 + Theme.space3 : Theme.space3 * 2)

  Rectangle {
    anchors.fill: parent
    radius: card.banner ? Theme.radius : 0
    color: card.banner ? Theme.glass : "transparent"
    border.width: card.banner ? 1 : 0
    border.color: Theme.edge
  }

  Rectangle {
    visible: card.urgency === NotificationUrgency.Critical
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 2
    color: Theme.red
  }

  Rectangle {
    visible: !card.banner
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 1
    color: Theme.separator
  }

  Column {
    id: contentColumn
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.leftMargin: card.banner ? Theme.space3 : Theme.panelPadding
    anchors.rightMargin: card.banner ? Theme.space3 : Theme.panelPadding
    anchors.topMargin: card.banner ? Theme.space2 : Theme.space3
    spacing: Theme.space2

    Item {
      width: parent.width
      height: Math.max(20, appText.implicitHeight, closeButton.implicitHeight)

      Text {
        id: appBadge
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        text: Theme.appMark(card.live ? card.live.desktopEntry || card.appName : card.appName)
        color: Theme.muted
        font.family: Theme.mono
        font.pixelSize: Theme.fontBody
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }

      Text {
        id: appText
        anchors.left: appBadge.right
        anchors.leftMargin: Theme.space2
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, timeText.x - appText.x - Theme.space2)
        text: card.appName || "System"
        color: Theme.muted
        font.family: Theme.mono
        font.pixelSize: Theme.fontTiny
        elide: Text.ElideRight
      }

      Text {
        id: timeText
        anchors.right: closeButton.left
        anchors.rightMargin: Theme.space2
        anchors.verticalCenter: parent.verticalCenter
        text: Notices.relativeTime(card.record.timeMs)
        color: Theme.dim
        font.family: Theme.mono
        font.pixelSize: Theme.fontTiny
      }

      IconButton {
        id: closeButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        size: 20
        z: 2
        name: "close"
        onClicked: {
          // A banner's X only takes the banner away; the notification itself
          // stays in the panel until it is dismissed there.
          if (card.banner)
            Notices.hideBanner(card.record.id);
          else
            Notices.dismiss(card.record);
        }
      }
    }

    Item {
      width: parent.width
      implicitHeight: message.implicitHeight

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Notices.activate(card.record)
      }

      Column {
        id: message
        width: parent.width
        spacing: Theme.space2

        Text {
          width: parent.width
          text: card.summary
          color: Theme.text
          font.family: Theme.reading
          font.pixelSize: Theme.fontTitle
          font.weight: Font.Medium
          wrapMode: Text.Wrap
          maximumLineCount: 2
          elide: Text.ElideRight
        }

        Text {
          visible: card.body !== ""
          width: parent.width
          text: card.body
          textFormat: Text.PlainText
          color: Theme.muted
          font.family: Theme.reading
          font.pixelSize: Theme.fontBody
          lineHeight: 1.35
          wrapMode: Text.Wrap
          maximumLineCount: 6
          elide: Text.ElideRight
        }
      }
    }

    Column {
      visible: card.actions.length > 0
      width: parent.width
      spacing: Theme.space2

      Repeater {
        model: card.actions

        delegate: ActionButton {
          required property var modelData
          width: parent.width
          text: modelData.text
          enabled: card.live !== null
          onClicked: Notices.invoke(card.record, modelData.identifier)
        }
      }
    }

    Text {
      visible: card.banner && card.record.transient
      width: parent.width
      text: "Transient · not saved to history"
      color: Theme.dim
      font.family: Theme.reading
      font.pixelSize: Theme.fontMicro
      wrapMode: Text.Wrap
    }
  }
}
