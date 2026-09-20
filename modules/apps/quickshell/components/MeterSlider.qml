import QtQuick
import qs

Item {
  id: slider

  property real value: 0
  property real from: 0
  property real to: 1
  property bool live: false

  property real dragValue: value

  signal moved(real value)
  signal committed(real value)

  readonly property bool dragging: mouse.pressed

  readonly property real ratio: {
    const span = to - from;
    if (span <= 0)
      return 0;
    const current = dragging ? dragValue : value;
    return Math.max(0, Math.min(1, (current - from) / span));
  }

  implicitHeight: 22
  opacity: enabled ? 1 : 0.45

  Rectangle {
    id: track
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    height: 3
    radius: 1
    color: Theme.track

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: Math.max(0, parent.width * slider.ratio)
      radius: 1
      color: Theme.accent
    }
  }

  Rectangle {
    width: 9
    height: 9
    radius: 4.5
    color: Theme.text
    border.width: 1
    border.color: Theme.thumbBorder
    x: Math.max(0, Math.min(track.width - width, track.width * slider.ratio - width / 2))
    anchors.verticalCenter: parent.verticalCenter
  }

  function valueAt(x) {
    const span = to - from;
    const ratio = track.width > 0 ? Math.max(0, Math.min(1, x / track.width)) : 0;
    return from + span * ratio;
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    enabled: slider.enabled

    onPressed: function(event) {
      slider.dragValue = slider.valueAt(event.x);
      if (slider.live)
        slider.moved(slider.dragValue);
    }

    onPositionChanged: function(event) {
      if (!mouse.pressed)
        return;
      slider.dragValue = slider.valueAt(event.x);
      if (slider.live)
        slider.moved(slider.dragValue);
    }

    onReleased: function(event) {
      slider.dragValue = slider.valueAt(event.x);
      slider.moved(slider.dragValue);
      slider.committed(slider.dragValue);
    }

    onCanceled: {
      slider.dragValue = slider.value;
    }
  }
}
