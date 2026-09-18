import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// Single popup host: one interactive surface exists for the whole shell, and
// its geometry follows the invoking output and bar control.
Scope {
  // Capture clicks on the desktop area while a popup is open. Layer Top sits
  // above normal windows but below the Overlay popup, and the bar margins
  // keep the bars interactive.
  PanelWindow {
    id: catcher

    visible: ShellState.open
    screen: ShellState.screen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-clickcatcher"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    margins.top: Theme.barHeight
    margins.bottom: Theme.barHeight

    MouseArea {
      anchors.fill: parent
      onClicked: ShellState.close()
    }
  }

  PanelWindow {
    id: host

    readonly property int availableWidth: host.screen ? host.screen.width : 1920
    readonly property int availableHeight: host.screen ? host.screen.height : 1080
    readonly property int maxContentHeight: Math.max(160, host.availableHeight - Theme.barHeight * 2 - Theme.space4)

    visible: ShellState.open
    screen: ShellState.screen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellState.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors.top: ShellState.open && (!ShellState.bottom || ShellState.drawer)
    anchors.bottom: ShellState.open && (ShellState.bottom || ShellState.drawer)
    anchors.left: ShellState.open && !ShellState.drawer
    anchors.right: ShellState.open && ShellState.drawer

    margins.top: ShellState.drawer ? Theme.barHeight : Theme.barHeight + Theme.space1
    margins.bottom: ShellState.drawer ? Theme.barHeight : Theme.barHeight + Theme.space1
    margins.left: ShellState.drawer ? 0 : Math.max(
      Theme.space2,
      Math.min(
        ShellState.anchorX - host.implicitWidth / 2,
        host.availableWidth - host.implicitWidth - Theme.space2
      )
    )

    implicitWidth: ShellState.drawer ? Math.min(Theme.drawerWidth, host.availableWidth) : Math.min(ShellState.popupWidth, host.availableWidth - Theme.space4)
    implicitHeight: ShellState.drawer ? Math.max(160, host.availableHeight - Theme.barHeight * 2) : Math.min(loader.item ? loader.item.implicitHeight : 0, host.maxContentHeight)

    FocusScope {
      id: scope
      anchors.fill: parent
      focus: true
      Keys.onEscapePressed: function(event) {
        ShellState.close();
        event.accepted = true;
      }

      Loader {
        id: loader
        width: parent.width
        height: parent.height
        source: ShellState.popupFile

        onLoaded: if (item && item.maxHeight !== undefined)
          item.maxHeight = host.maxContentHeight
      }
    }

    Connections {
      target: ShellState

      function onKindChanged() {
        if (ShellState.open)
          scope.forceActiveFocus();
      }
    }

    onVisibleChanged: {
      if (visible)
        scope.forceActiveFocus();
    }
  }
}
