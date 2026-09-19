import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.work

// Work in flight: every agent herdr knows about, one line each, ordered by
// attention. Rows are read-only text; clicking one opens that agent. Herdr
// owns the state, the shell only reports it.
ScrollFrame {
  id: panel

  padding: 0
  panelWidth: 400

  // Attention order. The last section that has rows is flagged so its final row
  // can drop its rule: the footer's divider follows immediately.
  readonly property var sections: {
    const all = [
      { "key": "needs", "title": "Needs you", "rows": WorkInFlight.needsRows, "last": false },
      { "key": "ready", "title": "Ready when you are", "rows": WorkInFlight.readyRows, "last": false },
      { "key": "working", "title": "In progress", "rows": WorkInFlight.workingRows, "last": false },
      { "key": "idle", "title": "Idle", "rows": WorkInFlight.idleRows, "last": false }
    ];
    let lastKey = "";
    for (let i = 0; i < all.length; i++) {
      if (all[i].rows.length > 0)
        lastKey = all[i].key;
    }
    for (let i = 0; i < all.length; i++)
      all[i].last = all[i].key === lastKey;
    return all;
  }

  Item {
    width: parent ? parent.width : panel.panelWidth
    implicitHeight: heading.implicitHeight + Theme.space5 + Theme.space3

    PopupHeader {
      id: heading
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.leftMargin: Theme.panelPadding
      anchors.rightMargin: Theme.panelPadding
      anchors.topMargin: Theme.space5
      title: "Work in flight"
      titleFamily: Theme.reading
      titleSize: Theme.fontHeading
      titleWeight: Font.Medium
      note: "You can leave these here. Finished work will wait."
      onCloseRequested: ShellState.close()
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: 1
      color: Theme.separator
    }
  }

  // Source honesty: a lost socket or an unsupported protocol says so before
  // any row is read.
  Item {
    width: parent ? parent.width : panel.panelWidth
    visible: WorkInFlight.sourceTrouble
    implicitHeight: sourceNotice.implicitHeight + Theme.space3 * 2

    Rectangle {
      anchors.fill: parent
      color: WorkInFlight.sourceState === "incompatible" ? Theme.attentionFill : "transparent"
    }

    RowLayout {
      id: sourceNotice
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Theme.panelPadding
      anchors.rightMargin: Theme.panelPadding
      spacing: Theme.space2

      Icon {
        Layout.alignment: Qt.AlignVCenter
        name: "blocked"
        color: WorkInFlight.sourceState === "incompatible" ? Theme.amber : Theme.dim
        size: 13
      }

      Text {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        text: WorkInFlight.sourceLine
        color: WorkInFlight.sourceState === "incompatible" ? Theme.amber : Theme.muted
        font.family: Theme.reading
        font.pixelSize: Theme.fontSmall
        wrapMode: Text.Wrap
      }
    }
  }

  Repeater {
    model: panel.sections

    delegate: Item {
      id: sectionItem

      required property var modelData

      readonly property var section: modelData

      width: panel.width
      visible: sectionItem.section.rows.length > 0
      implicitHeight: sectionColumn.implicitHeight

      Column {
        id: sectionColumn
        width: parent.width
        spacing: 0

        Item {
          width: parent.width
          implicitHeight: sectionTitle.implicitHeight + Theme.space3

          Text {
            id: sectionTitle
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: Theme.panelPadding
            anchors.rightMargin: Theme.panelPadding
            text: sectionItem.section.title + " · " + sectionItem.section.rows.length
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: Theme.fontTiny
          }
        }

        Repeater {
          model: sectionItem.section.rows

          delegate: AgentRow {
            required property var modelData
            required property int index

            row: modelData
            divider: !(sectionItem.section.last && index === sectionItem.section.rows.length - 1)
          }
        }
      }
    }
  }

  Item {
    width: parent ? parent.width : panel.panelWidth
    implicitHeight: footerColumn.implicitHeight + Theme.space3 + Theme.space5

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: 1
      color: Theme.separator
    }

    Column {
      id: footerColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.leftMargin: Theme.panelPadding
      anchors.rightMargin: Theme.panelPadding
      anchors.topMargin: Theme.space3
      spacing: Theme.space2

      Text {
        width: parent.width
        text: WorkInFlight.sourceLine
        color: Theme.dim
        font.family: Theme.mono
        font.pixelSize: Theme.fontMicro
        wrapMode: Text.Wrap
      }

    }
  }
}
