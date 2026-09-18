import QtQuick
import Quickshell

Scope {
  id: bar

  property var modelData
  property var screen: modelData

  TopBar {
    screen: bar.screen
  }

  BottomBar {
    screen: bar.screen
  }
}
