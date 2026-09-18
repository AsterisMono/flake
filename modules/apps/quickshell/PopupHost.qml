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

    anchors.top: ShellState.open && !ShellState.bottom
    anchors.bottom: ShellState.open && ShellState.bottom
    anchors.left: ShellState.open

    margins.top: Theme.barHeight + Theme.space1
    margins.bottom: Theme.barHeight + Theme.space1
    // Every popup keeps the same inset from the output's edge. SwayFX samples
    // its layer blur past the surface's border, so a surface that sits flush
    // against the screen edge keeps a faint bright band along that edge.
    margins.left: Math.max(
      Theme.space2,
      Math.min(
        ShellState.anchorX - host.implicitWidth / 2,
        host.availableWidth - host.implicitWidth - Theme.space2
      )
    )

    implicitWidth: Math.min(ShellState.popupWidth, host.availableWidth - Theme.space4)
    implicitHeight: Math.min(loader.item ? loader.item.implicitHeight : 0, host.maxContentHeight)

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
