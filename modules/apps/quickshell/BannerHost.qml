import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.components

// Notification banners: the transient half of the notification record, shown
// on the output the notification arrived on. They sit under the top bar on the
// right and step aside while the notification column is open.
Scope {
  PanelWindow {
    id: host

    visible: Notices.banners.length > 0
    screen: Notices.bannerScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-banner"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.top: true
    anchors.right: true
    margins.top: Theme.barHeight + Theme.space2
    margins.right: ShellState.kind === "notifications" ? Theme.drawerWidth + Theme.space4 : Theme.space3

    implicitWidth: Theme.bannerWidth
    implicitHeight: column.implicitHeight

    Column {
      id: column
      width: parent.width
      spacing: Theme.space2

      Repeater {
        model: Notices.bannerRecords

        delegate: NoticeRow {
          banner: true
        }
      }
    }
  }
}
