pragma Singleton
import QtQuick
import Quickshell
import qs

// The on-screen display: the one transient card that answers "what did I just
// change, and to what" for the sink's volume and mute and for the display
// backlight.
//
// It is driven by the state the machine reports, never by the keys that changed
// it. The compositor owns the XF86 bindings, so a card wired to key presses
// would miss the wheel on the bar, the popup's own slider and anything else
// that moves the sink, and it could not tell a write the backlight rejected
// from one it accepted. Both channels below are readings instead: Pipewire's
// signals for the sink, and the backlight file that Brightness watches.
Singleton {
  id: osd

  // "" | "audio" | "brightness". There is one card and not a queue of them: a
  // change replaces what is on screen.
  property string kind: ""

  // The output the card is on. Sampled when the card appears and kept until it
  // disappears, so switching between volume and brightness - or changing focus
  // with the card up - cannot make it jump between outputs.
  property var screen: null

  readonly property bool active: osd.kind !== ""

  readonly property int cardWidth: Theme.osdWidth
  // Measured by the plate itself and published by OsdHost: the card's height
  // follows whatever the theme's type scale needs, and the test below has to
  // know the rectangle the card really covers. Until it is published the card
  // has no rectangle, and no popup can be in its way.
  property int cardHeight: 0
  readonly property int cardMargin: Theme.barHeight + Theme.space4

  // Where the card is, on its output. Only the popup test below reads it.
  readonly property rect cardFrame: {
    const target = osd.screen;
    if (!target)
      return Qt.rect(0, 0, 0, 0);
    return Qt.rect(
      Math.round((target.width - osd.cardWidth) / 2),
      Math.round(target.height - osd.cardMargin - osd.cardHeight),
      osd.cardWidth,
      osd.cardHeight
    );
  }

  // Observation baselines. -1 is "no reading yet", which is not zero: the first
  // reading of a channel is where that channel started, not an adjustment, so a
  // shell that has just started or reloaded presents nothing at all.
  property int audioPercent: -1
  property bool audioMuted: false
  property int brightnessPercent: -1

  // A source that has just appeared reports a placeholder before it reports
  // what it holds: a sink Pipewire has only just bound reads as zero volume,
  // and a backlight reads as zero until the poll names its device. The first
  // reading is therefore not trusted on its own - until one has stood still for
  // a moment, an arrival only moves the baseline, and the first card a channel
  // ever shows is a change made after it was steady.
  property bool audioSettled: false
  property bool brightnessSettled: false

  function observeAudio() {
    if (!Audio.available) {
      osd.audioPercent = -1;
      osd.audioSettled = false;
      audioSettle.stop();
      if (osd.kind === "audio")
        osd.hide();
      return;
    }

    const percent = Math.round(Audio.volume * 100);
    const muted = Audio.muted;
    if (!osd.audioSettled) {
      osd.audioPercent = percent;
      osd.audioMuted = muted;
      audioSettle.restart();
      return;
    }

    // The same state can arrive twice, and a step smaller than the whole
    // percent the card displays is not a change it could show.
    if (percent === osd.audioPercent && muted === osd.audioMuted)
      return;

    osd.audioPercent = percent;
    osd.audioMuted = muted;
    osd.present("audio");
  }

  function observeBrightness() {
    if (!Brightness.available) {
      osd.brightnessPercent = -1;
      osd.brightnessSettled = false;
      brightnessSettle.stop();
      if (osd.kind === "brightness")
        osd.hide();
      return;
    }

    const percent = Math.round(Brightness.percent);
    if (!osd.brightnessSettled) {
      osd.brightnessPercent = percent;
      brightnessSettle.restart();
      return;
    }

    if (percent === osd.brightnessPercent)
      return;

    osd.brightnessPercent = percent;
    osd.present("brightness");
  }

  // A popup owns the moment: it is the surface the user is working in, it holds
  // keyboard focus, and its catcher holds the pointer. The audio and power
  // popups also show the very reading this card would repeat, live. Everything
  // else gives way only when it would actually overlap the card - the Work,
  // Windows and notification surfaces reach into the card's band on a narrow
  // output, and a popup the card cannot touch leaves it alone.
  function suppressed(next) {
    if (!ShellState.open)
      return false;
    if (next === "audio" && ShellState.kind === "audio")
      return true;
    if (next === "brightness" && ShellState.kind === "power")
      return true;
    if (ShellState.screen !== osd.screen)
      return false;
    return osd.overlaps(ShellState.frame, osd.cardFrame, Theme.space2);
  }

  function overlaps(popup, card, clearance) {
    if (popup.width <= 0 || popup.height <= 0)
      return false;
    return popup.x < card.x + card.width + clearance
      && card.x < popup.x + popup.width + clearance
      && popup.y < card.y + card.height + clearance
      && card.y < popup.y + popup.height + clearance;
  }

  function present(next) {
    if (!osd.active)
      osd.screen = Desktop.focusedScreen || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);

    // The baseline above has already taken this change into account, so a
    // suppressed one is discarded rather than replayed when the popup closes.
    if (osd.suppressed(next))
      return;

    osd.kind = next;
    hold.restart();
  }

  function hide() {
    osd.kind = "";
  }

  // A card that is up when a popup opens steps aside at once. Nothing brings it
  // back afterwards: by then the readings it would have shown are history.
  readonly property bool relinquished: osd.active && osd.suppressed(osd.kind)

  onRelinquishedChanged: {
    if (osd.relinquished)
      osd.hide();
  }

  // Long enough to read a two digit value off the bottom of a screen, short
  // enough that the card is gone before most changes need the space again.
  Timer {
    id: hold
    interval: 1200
    onTriggered: osd.hide()
  }

  // Long enough for a source that has just appeared to say what it holds, short
  // enough that a change made just after a reload is still presented.
  Timer {
    id: audioSettle
    interval: 300
    onTriggered: osd.audioSettled = true
  }

  Timer {
    id: brightnessSettle
    interval: 300
    onTriggered: osd.brightnessSettled = true
  }

  Connections {
    target: Audio

    function onVolumeChanged() {
      osd.observeAudio();
    }

    function onMutedChanged() {
      osd.observeAudio();
    }

    function onAvailableChanged() {
      osd.observeAudio();
    }

    // A different sink is a different setting, not a change to this one, and it
    // arrives with a reading of its own.
    function onSinkChanged() {
      osd.audioSettled = false;
      osd.observeAudio();
    }
  }

  Connections {
    target: Brightness

    function onPercentChanged() {
      osd.observeBrightness();
    }

    function onAvailableChanged() {
      osd.observeBrightness();
    }

    // Likewise for a backlight that was replaced: the reading is new, the
    // setting did not move.
    function onDeviceChanged() {
      osd.brightnessSettled = false;
      osd.observeBrightness();
    }
  }

  // An output that goes away takes the card with it, the same way it closes a
  // popup that was anchored to it.
  Connections {
    target: Quickshell

    function onScreensChanged() {
      const screens = Quickshell.screens;
      let present = false;
      for (let i = 0; i < screens.length; i++) {
        if (screens[i] === osd.screen)
          present = true;
      }
      if (osd.screen !== null && !present)
        osd.hide();
    }
  }

  Component.onCompleted: {
    osd.observeAudio();
    osd.observeBrightness();
  }
}
