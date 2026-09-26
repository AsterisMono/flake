import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs
import qs.components

PopupFrame {
  id: popup

  PopupHeader {
    title: Power.hasBattery ? "Battery" : "Power"
    onCloseRequested: ShellState.close()
  }

  Item {
    visible: Power.hasBattery
    width: parent.width
    height: 54

    Text {
      anchors.left: parent.left
      anchors.top: parent.top
      text: Math.round(Power.percent) + "%"
      color: Theme.text
      font.family: Theme.mono
      font.pixelSize: Theme.fontDisplay
    }

    Text {
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      text: Power.batteryState + (Power.batteryTime !== "" ? " · " + Power.batteryTime : "")
      color: Theme.muted
      font.family: Theme.reading
      font.pixelSize: Theme.fontSmall
    }
  }

  // The display backlight lives here rather than in the bar: it is one more
  // machine control, and the bar already carries a reading for every other
  // device it shows.
  RowLayout {
    width: parent.width
    visible: Brightness.available
    spacing: Theme.space2

    Text {
      Layout.fillWidth: true
      text: "Brightness"
      color: Theme.muted
      font.family: Theme.mono
      font.pixelSize: Theme.fontTiny
      font.letterSpacing: 1.1
    }

    Icon {
      Layout.alignment: Qt.AlignVCenter
      name: Brightness.indicatorIcon
      color: Theme.muted
      size: Theme.iconSize
    }

    Text {
      Layout.alignment: Qt.AlignVCenter
      text: Math.round(Brightness.shownPercent) + "%"
      color: Theme.text
      font.family: Theme.mono
      font.pixelSize: Theme.fontBody
    }
  }

  MeterSlider {
    width: parent.width
    visible: Brightness.available
    from: 0
    to: 100
    value: Brightness.shownPercent
    live: true
    onMoved: Brightness.setPercent(value)
  }

  Text {
    width: parent.width
    visible: Brightness.failed
    text: "The backlight did not accept that change; the reading above is what the machine reports."
    color: Theme.attention
    font.family: Theme.reading
    font.pixelSize: Theme.fontTiny
    wrapMode: Text.Wrap
  }

  Text {
    width: parent.width
    text: "Power profile"
    color: Theme.muted
    font.family: Theme.mono
    font.pixelSize: Theme.fontTiny
    font.letterSpacing: 1.1
  }

  ColumnLayout {
    width: parent.width
    spacing: Theme.space2

    ActionButton {
      Layout.fillWidth: true
      icon: "leaf"
      text: "Power saver"
      selected: Power.profile === PowerProfile.PowerSaver
      onClicked: Power.setProfile(PowerProfile.PowerSaver)
    }

    ActionButton {
      Layout.fillWidth: true
      icon: "profileBalanced"
      text: "Balanced"
      selected: Power.profile === PowerProfile.Balanced
      onClicked: Power.setProfile(PowerProfile.Balanced)
    }

    ActionButton {
      Layout.fillWidth: true
      icon: "profilePerformance"
      text: "Performance"
      selected: Power.profile === PowerProfile.Performance
      enabled: Power.performanceAvailable
      onClicked: Power.setProfile(PowerProfile.Performance)
    }
  }

  Text {
    width: parent.width
    visible: !Power.performanceAvailable
    text: "This machine does not offer a Performance profile."
    color: Theme.muted
    font.family: Theme.reading
    font.pixelSize: Theme.fontTiny
    wrapMode: Text.Wrap
  }

  Text {
    width: parent.width
    visible: Power.degradationReason !== PerformanceDegradationReason.None
    text: "Performance is currently reduced by the system."
    color: Theme.attention
    font.family: Theme.reading
    font.pixelSize: Theme.fontTiny
    wrapMode: Text.Wrap
  }

  Rectangle {
    width: parent.width
    height: 1
    color: Theme.separator
  }

  ActionButton {
    width: parent.width
    icon: Power.awakeActive ? "eye" : "eyeOff"
    text: "Keep awake"
    selected: Power.awakeActive
    onClicked: Power.setAwake(!Power.awakeActive, Power.awakeMinutes || 60)
  }

  RowLayout {
    width: parent.width
    spacing: Theme.space2

    ActionButton {
      Layout.fillWidth: true
      text: "30 min"
      selected: Power.awakeActive && Power.awakeMinutes === 30
      onClicked: Power.setAwake(true, 30)
    }

    ActionButton {
      Layout.fillWidth: true
      text: "1 hour"
      selected: Power.awakeActive && Power.awakeMinutes === 60
      onClicked: Power.setAwake(true, 60)
    }

    ActionButton {
      Layout.fillWidth: true
      text: "Until off"
      selected: Power.awakeActive && Power.awakeMinutes === 0
      onClicked: Power.setAwake(true, 0)
    }
  }

  Text {
    width: parent.width
    text: Power.awakeActive
      ? Power.awakeSummary + ". Automatic dimming, screen off and sleep are paused; locking by hand and by closing a laptop lid still work."
      : "Pauses automatic dimming, screen off and sleep while you read or present. Locking by hand and by closing a laptop lid still work."
    color: Theme.muted
    font.family: Theme.reading
    font.pixelSize: Theme.fontTiny
    wrapMode: Text.Wrap
    lineHeight: 1.4
  }
}
