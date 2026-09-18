//@ pragma UseQApplication
//@ pragma NativeTextRendering
//@ pragma ShellId desk-bars
//@ pragma AppId org.nvirellia.DeskBars

import QtQuick
import Quickshell

ShellRoot {
  Variants {
    model: Quickshell.screens

    Bar {
      screen: modelData
    }
  }

  PopupHost {}
  BannerHost {}
}
