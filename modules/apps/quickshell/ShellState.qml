pragma Singleton
import QtQuick
import Quickshell
import qs.work

// One interactive popup is open across the whole shell at a time.
Singleton {
  id: state

  property string kind: ""
  property var screen: null
  property real anchorX: 0

  // The open popup's own rectangle on its output, in output-local coordinates,
  // published by PopupHost. The OSD is the only other transient surface the
  // shell puts on an output, and it yields to a popup it would overlap; this is
  // the one place that geometry exists.
  property rect frame: Qt.rect(0, 0, 0, 0)

  readonly property bool open: kind !== ""
  readonly property bool bottom: kind === "windows" || kind === "work"
  readonly property int popupWidth: kind === "work" ? 400 : kind === "notifications" ? Theme.noticePanelWidth : Theme.popupWidth

  readonly property string popupFile: {
    switch (kind) {
    case "clock":
      return "popups/CalendarPopup.qml";
    case "identity":
      return "popups/IdentityPopup.qml";
    case "media":
      return "popups/MediaPopup.qml";
    case "health":
      return "popups/HealthPopup.qml";
    case "power":
      return "popups/PowerPopup.qml";
    case "audio":
      return "popups/AudioPopup.qml";
    case "windows":
      return "popups/WindowListPopup.qml";
    case "work":
      return "popups/WorkPopup.qml";
    case "notifications":
      return "popups/NotificationCenter.qml";
    default:
      return "";
    }
  }

  function toggle(kind, screen, anchorX) {
    if (state.kind === kind && state.screen === screen) {
      state.close();
      return;
    }

    if (kind === "notifications")
      Notices.markAllRead();
    if (kind === "work")
      WorkInFlight.refresh();

    state.kind = kind;
    state.screen = screen;
    state.anchorX = anchorX;
  }

  function close() {
    state.kind = "";
    state.screen = null;
  }

  Connections {
    target: Quickshell

    function onScreensChanged() {
      const screens = Quickshell.screens;
      let present = false;
      for (let i = 0; i < screens.length; i++) {
        if (screens[i] === state.screen)
          present = true;
      }
      if (state.screen !== null && !present)
        state.close();
    }
  }

}
