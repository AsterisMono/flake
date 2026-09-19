import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import qs
import qs.components

PanelWindow {
  id: bar

  readonly property bool compact: bar.width < 1180
  readonly property bool narrow: bar.width < 820

  anchors.top: true
  anchors.left: true
  anchors.right: true
  implicitHeight: Theme.barHeight
  exclusiveZone: Theme.barHeight
  color: "transparent"
  WlrLayershell.namespace: "quickshell-bar-top"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Rectangle {
    anchors.fill: parent
    color: Theme.barGlass(Desktop.workspaceOccupied(bar.screen))

    Behavior on color {
      ColorAnimation {
        duration: Theme.motion
      }
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: 1
      color: Theme.edge
    }
  }

  // Attached to a long-lived bar surface so closing a popup cannot end it.
  IdleInhibitor {
    window: bar
    enabled: Power.awakeActive
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  RowLayout {
    id: leftRow
    anchors.left: parent.left
    anchors.leftMargin: Theme.space2
    anchors.verticalCenter: parent.verticalCenter
    // Button padding carries the new breathing room, so the row gap shrinks by
    // the same amount: the distance across a separator is unchanged.
    spacing: Theme.space2

    BarButton {
      id: clockButton
      active: ShellState.kind === "clock"
      onClicked: ShellState.toggle("clock", bar.screen, Theme.centerX(clockButton))

      // The flag is the trans flag emoji, as the waybar bar rendered it, not a
      // drawn rectangle: the emoji font supplies the artwork.
      Text {
        Layout.alignment: Qt.AlignVCenter
        text: "🏳️‍⚧️"
        font.family: Theme.emoji
        font.pixelSize: Theme.fontBody
      }

      Text {
        id: clockText
        Layout.alignment: Qt.AlignVCenter
        textFormat: Text.StyledText
        text: {
          const date = Qt.formatDateTime(clock.date, "ddd d MMM");
          const time = Qt.formatDateTime(clock.date, "HH:mm");
          if (bar.compact)
            return "<font color=\"" + Theme.muted + "\">" + time + "</font>";
          return "<font color=\"" + Theme.muted + "\">" + date + "</font>"
            + "<font color=\"" + Theme.dim + "\"> · </font>"
            + "<font color=\"" + Theme.muted + "\">" + time + "</font>";
        }
        font.family: Theme.mono
        font.pixelSize: Theme.fontBody
      }
    }

    Separator {}

    BarButton {
      id: identityButton
      gap: Theme.space2
      active: ShellState.kind === "identity"
      onClicked: ShellState.toggle("identity", bar.screen, Theme.centerX(identityButton))

      Text {
        id: identityVersion
        Layout.alignment: Qt.AlignVCenter
        text: "NixOS " + Runtime.nixosVersion
        color: Theme.muted
        font.family: Theme.mono
        font.pixelSize: Theme.fontBody
      }
    }
  }

  Item {
    id: centerZone
    width: Math.max(0, Math.min(380, bar.width - leftRow.width - rightRow.width - 56))
    height: Theme.barHeight
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    visible: width > 70 && Media.available

    BarButton {
      id: mediaButton
      anchors.centerIn: parent
      width: Math.min(implicitWidth, centerZone.width)
      active: ShellState.kind === "media"
      onClicked: ShellState.toggle("media", bar.screen, Theme.centerX(mediaButton))

      Icon {
        Layout.alignment: Qt.AlignVCenter
        name: !Media.available ? "music" : (Media.playing ? "pause" : "play")
        color: Theme.dim
        size: Theme.iconSmall
      }

      Text {
        Layout.maximumWidth: 280
        text: Media.available ? Media.displayText : "Nothing playing"
        color: Media.available ? Theme.muted : Theme.dim
        font.family: Theme.mono
        font.pixelSize: Theme.fontBody
        elide: Text.ElideRight
      }
    }
  }

  RowLayout {
    id: rightRow
    anchors.right: parent.right
    anchors.rightMargin: 0
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.space1

    BarButton {
      id: healthButton
      gap: Theme.space3
      active: ShellState.kind === "health"
      onClicked: ShellState.toggle("health", bar.screen, Theme.centerX(healthButton))

      Waycat {
        color: Health.pressureLevel === 2 ? Theme.red : Theme.muted
        size: 19
      }

      Separator {
        visible: !bar.compact
      }

      RowLayout {
        visible: !bar.compact
        spacing: Theme.space3

        Metric {
          visible: Health.netValid
          name: "up"
          value: Health.rateValue(Health.netUp)
          unit: Health.rateUnit(Health.netUp)
        }

        Metric {
          visible: Health.netValid
          name: "down"
          value: Health.rateValue(Health.netDown)
          unit: Health.rateUnit(Health.netDown)
        }

        Separator {
          visible: Health.hasTemp || Health.valid
        }

        Metric {
          visible: Health.hasTemp
          name: "temp"
          value: Health.temperature.toFixed(0)
          unit: "°C"
        }

        Metric {
          visible: Health.valid
          name: "memory"
          value: Math.round(Health.memoryPercent)
          unit: "%"
        }

        Metric {
          visible: Health.failedTotal > 0
          name: "alert"
          value: Health.failedTotal
          color: Theme.red
          iconColor: Theme.red
        }
      }

      Metric {
        visible: Health.pressureLevel > 0
        name: "alert"
        value: "PSI " + Math.round(Health.psiSome60) + "%"
        color: Health.pressureLevel === 2 ? Theme.red : Theme.amber
        iconColor: Health.pressureLevel === 2 ? Theme.red : Theme.amber
      }
    }

    Separator {}

    BarButton {
      id: powerButton
      active: ShellState.kind === "power"
      onClicked: ShellState.toggle("power", bar.screen, Theme.centerX(powerButton))

      Icon {
        Layout.alignment: Qt.AlignVCenter
        name: Power.indicatorIcon
        color: Power.awakeActive ? Theme.accent : Theme.muted
        size: Theme.iconSize
      }

      Text {
        id: powerText
        Layout.alignment: Qt.AlignVCenter
        visible: Power.hasBattery
        text: Math.round(Power.percent) + "%"
        color: Theme.muted
        font.family: Theme.mono
        font.pixelSize: Theme.fontBody
      }

      Icon {
        Layout.alignment: Qt.AlignVCenter
        visible: Power.awakeActive
        name: "eye"
        color: Theme.accent
        size: Theme.iconSmall
      }
    }

    BarButton {
      id: audioButton
      active: ShellState.kind === "audio"
      onClicked: ShellState.toggle("audio", bar.screen, Theme.centerX(audioButton))
      onMiddleClicked: Audio.toggleMute()
      onRightClicked: Quickshell.execDetached([Runtime.pavucontrol])
      onWheeled: function(delta, horizontal) {
        if (!horizontal)
          Audio.adjust(delta > 0 ? 0.01 : -0.01);
      }

      Icon {
        Layout.alignment: Qt.AlignVCenter
        name: Audio.indicatorIcon
        color: Audio.muted ? Theme.dim : Theme.muted
        size: Theme.iconSize
      }

      Text {
        id: volumeText
        Layout.alignment: Qt.AlignVCenter
        visible: !bar.narrow && Audio.available
        text: Math.round(Audio.volume * 100) + "%"
        color: Theme.muted
        font.family: Theme.mono
        font.pixelSize: Theme.fontBody
      }
    }

    RowLayout {
      spacing: 0

      Repeater {
        model: SystemTray.items.values

        delegate: BarButton {
          id: trayButton
          required property var modelData
          padding: Theme.space1

          onClicked: modelData.activate()
          onMiddleClicked: modelData.secondaryActivate()
          onRightClicked: function(event) {
            if (!modelData.hasMenu) {
              modelData.activate();
              return;
            }
            const point = bar.mapFromItem(trayButton, event.x, event.y);
            modelData.display(bar, Math.round(point.x), Math.round(point.y));
          }

          Image {
            visible: modelData.icon !== ""
            source: modelData.icon
            sourceSize.width: 16
            sourceSize.height: 16
            fillMode: Image.PreserveAspectFit
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            Layout.maximumWidth: 16
            Layout.maximumHeight: 16
          }
        }
      }
    }

    BarButton {
      id: bellButton
      Layout.minimumWidth: 40
      padding: Theme.space3
      leadingDivider: true
      active: ShellState.kind === "notifications"
      attention: Notices.hasUnreadCritical
      onClicked: ShellState.toggle("notifications", bar.screen, Theme.centerX(bellButton))

      Icon {
        Layout.alignment: Qt.AlignVCenter
        name: Notices.dnd ? "bellOff" : "bell"
        color: Notices.hasUnreadCritical ? Theme.amber : Theme.muted
        size: Theme.iconSize
      }

      Text {
        visible: Notices.unreadCount > 0
        text: Notices.unreadCount > 99 ? "99+" : String(Notices.unreadCount)
        color: Theme.accent
        font.family: Theme.mono
        font.pixelSize: Theme.fontSmall
      }
    }
  }

}
