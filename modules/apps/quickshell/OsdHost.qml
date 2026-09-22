import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.components

// The OSD card: one small plate at the bottom centre of the output the change
// happened on, under the notification banners' material rules and over
// everything else.
//
// The window is an overlay, so an ordinary fullscreen window still gets the
// feedback; it never takes keyboard focus; and its input region is empty, so a
// click where the card is passes through to whatever is underneath, including
// the popups' click catcher. The window carries no opacity of its own - the
// plate fades, and the surface stays mapped until the fade is over.
Scope {
  PanelWindow {
    id: host

    visible: Osd.active || plate.opacity > 0
    screen: Osd.screen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.bottom: true
    anchors.left: true
    // Centred on the output, with the bottom bar's own space kept clear
    // underneath.
    margins.left: Math.max(
      Theme.space2,
      Math.round(((host.screen ? host.screen.width : 0) - Osd.cardWidth) / 2)
    )
    margins.bottom: Osd.cardMargin

    implicitWidth: Osd.cardWidth
    implicitHeight: plate.implicitHeight

    // The OSD knows where its card would sit but not how tall the plate turned
    // out, so the plate publishes its own height for the popup test.
    Binding {
      target: Osd
      property: "cardHeight"
      value: host.implicitHeight
    }

    Rectangle {
      id: plate

      // The card reports what the machine holds, so the first reading of a
      // source that has just gone away is no reading at all.
      readonly property bool audio: Osd.kind === "audio"
      readonly property bool valid: plate.audio ? Audio.available : Brightness.available
      readonly property bool muted: plate.audio && Audio.muted
      // Whole numbers throughout: nothing a key, a wheel or a drag can do moves
      // a reading by less than the percent the card prints.
      readonly property int percent: Math.round(plate.audio ? Audio.volume * 100 : Brightness.percent)
      // Above unity is the one volume the popup can reach and the bar cannot
      // name, so the card names it rather than leaving a number over 100
      // unexplained.
      readonly property bool boost: plate.audio && plate.percent > 100
      readonly property string icon: plate.audio ? Audio.indicatorIcon : Brightness.indicatorIcon
      readonly property string label: {
        if (!plate.audio)
          return "Brightness";
        if (plate.muted)
          return "Muted";
        return plate.boost ? "Volume · boost" : "Volume";
      }
      readonly property string reading: plate.valid ? plate.percent + "%" : "—"
      // The gauge is the ordinary 0-100% range for both readings, so the two
      // cards have one scale between them. A muted sink keeps its level on that
      // scale: the word explains the silence, and an empty rail would say the
      // level had gone, which is not what muting does.
      readonly property real ratio: plate.valid ? Math.max(0, Math.min(1, plate.percent / 100)) : 0
      readonly property color fillColor: !plate.valid || plate.muted ? Theme.muted : plate.boost ? Theme.attention : Theme.accent
      // A read-only rail needs a touch more body than the slider's 3 px: a
      // slider carries a 9 px thumb, and this has only its own height to be
      // legible at a glance.
      readonly property int gaugeHeight: 4

      width: parent.width
      implicitHeight: content.implicitHeight + Theme.space4 * 2
      color: Theme.osdGlass
      border.width: 1
      border.color: Theme.edge
      radius: Theme.radius
      opacity: 0

      // Acknowledgement is quicker than departure: the card answers the moment
      // the change lands and leaves slowly enough to be read on its way out.
      // Halving the one motion token keeps both halves of the gesture in the
      // shell's scale, and neither slides, scales or bounces - a change already
      // arrives with motion of its own.
      NumberAnimation {
        id: appear
        target: plate
        property: "opacity"
        to: 1
        duration: Theme.motion / 2
        easing.type: Easing.OutQuad
      }

      NumberAnimation {
        id: disappear
        target: plate
        property: "opacity"
        to: 0
        duration: Theme.motion
        easing.type: Easing.OutQuad
      }

      Connections {
        target: Osd

        // A change that arrives while the card is on its way out turns it
        // around from wherever the fade had reached instead of replaying the
        // entrance.
        function onActiveChanged() {
          if (Osd.active) {
            disappear.stop();
            appear.start();
          } else {
            appear.stop();
            disappear.start();
          }
        }
      }

      Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.space4
        spacing: Theme.space3

        RowLayout {
          width: parent.width
          spacing: Theme.space3

          Icon {
            Layout.alignment: Qt.AlignVCenter
            name: plate.icon
            size: Theme.iconLarge
          }

          Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: plate.label
            color: Theme.muted
            font.family: Theme.mono
            font.pixelSize: Theme.fontSmall
            font.letterSpacing: 1.0
            font.capitalization: Font.AllUppercase
            elide: Text.ElideRight
          }

          Text {
            Layout.alignment: Qt.AlignVCenter
            text: plate.reading
            color: plate.valid && !plate.muted ? Theme.text : Theme.muted
            font.family: Theme.mono
            font.pixelSize: Theme.fontDisplay
            font.weight: Font.Medium
          }
        }

        Rectangle {
          width: parent.width
          height: plate.gaugeHeight
          radius: 1
          color: Theme.track

          Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(0, parent.width * plate.ratio)
            radius: 1
            color: plate.fillColor
          }
        }
      }
    }
  }
}
