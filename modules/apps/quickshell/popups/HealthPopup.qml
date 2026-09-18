import QtQuick
import Quickshell
import qs
import qs.components

ScrollFrame {
  id: popup

  padding: Theme.panelPadding

  readonly property color pressureColor: Health.pressureLevel === 2 ? Theme.red : Theme.amber

  readonly property var rows: {
    const result = [];
    const missing = Health.valid ? "" : "unavailable";
    if (Runtime.sensorPath !== "")
      result.push({ "label": "CPU temperature", "value": missing !== "" ? missing : (Health.hasTemp ? Health.temperature.toFixed(1) + " °C" : "unavailable"), "color": missing === "" && Health.hasTemp ? Theme.text : Theme.dim });
    result.push({ "label": "Memory", "value": missing !== "" ? missing : Health.formatGib(Health.memoryUsed) + " / " + Health.formatGib(Health.memoryTotal) + " GiB", "color": missing === "" ? Theme.text : Theme.dim });
    result.push({ "label": "Swap", "value": missing !== "" ? missing : Health.formatGib(Health.swapUsed) + " / " + Health.formatGib(Health.swapTotal) + " GiB", "color": missing === "" ? Theme.text : Theme.dim });
    result.push({ "label": "Zswap / swapped", "value": missing !== "" ? missing : Health.formatGib(Health.zswap) + " / " + Health.formatGib(Health.zswapped) + " GiB", "color": missing === "" ? Theme.text : Theme.dim });
    result.push({ "label": "PSI some · 10 / 60 / 300 s", "value": missing !== "" ? missing : Health.psiSome10.toFixed(0) + " / " + Health.psiSome60.toFixed(0) + " / " + Health.psiSome300.toFixed(0) + "%", "color": missing === "" && Health.pressureLevel > 0 ? popup.pressureColor : (missing === "" ? Theme.text : Theme.dim) });
    result.push({ "label": "PSI full · 10 / 60 / 300 s", "value": missing !== "" ? missing : Health.psiFull10.toFixed(0) + " / " + Health.psiFull60.toFixed(0) + " / " + Health.psiFull300.toFixed(0) + "%", "color": missing === "" && Health.pressureLevel > 0 ? popup.pressureColor : (missing === "" ? Theme.text : Theme.dim) });
    result.push({ "label": "Network interface", "value": missing !== "" ? missing : (Health.netValid ? Health.iface : "unavailable"), "color": missing === "" && Health.netValid ? Theme.text : Theme.dim });
    result.push({ "label": "Upload / download", "value": missing !== "" ? missing : Health.formatRate(Health.netUp) + " / " + Health.formatRate(Health.netDown), "color": missing === "" ? Theme.text : Theme.dim });
    if (missing === "" && Health.failedTotal > 0)
      result.push({ "label": "Failed units · system / user", "value": Health.failedSystem + " / " + Health.failedUser, "color": Theme.red });
    return result;
  }

  PopupHeader {
    title: "System health"
    note: !Health.valid ? "Health metrics are unavailable." : (Health.stale ? "Showing the last sample; it may be out of date." : "")
    onCloseRequested: ShellState.close()
  }

  Repeater {
    model: popup.rows

    delegate: Item {
      required property var modelData
      width: popup.width - popup.padding * 2
      height: 24

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.58
        text: modelData.label
        color: Theme.muted
        font.family: Theme.mono
        font.pixelSize: Theme.fontSmall
        elide: Text.ElideRight
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.42
        horizontalAlignment: Text.AlignRight
        text: modelData.value
        color: modelData.color
        font.family: Theme.mono
        font.pixelSize: Theme.fontSmall
        elide: Text.ElideRight
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Qt.rgba(76 / 255, 86 / 255, 106 / 255, 0.44)
      }
    }
  }

  ActionButton {
    icon: "chart"
    text: "Open system monitor ↗"
    onClicked: {
      Quickshell.execDetached(Runtime.btopCommand);
      ShellState.close();
    }
  }
}
