pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
  id: media

  property string chosenAddress: ""
  property int positionTick: 0

  readonly property var players: Mpris.players.values

  // Prefer the player the user last interacted with, then anything playing.
  readonly property var player: {
    const list = media.players;
    if (media.chosenAddress) {
      for (let i = 0; i < list.length; i++) {
        if (list[i].dbusName === media.chosenAddress)
          return list[i];
      }
    }
    for (let i = 0; i < list.length; i++) {
      if (list[i].isPlaying)
        return list[i];
    }
    return list.length > 0 ? list[0] : null;
  }

  readonly property bool available: media.player !== null
  readonly property bool playing: media.player !== null && media.player.isPlaying

  readonly property string displayText: {
    const current = media.player;
    if (!current)
      return "";
    const title = current.trackTitle || "Unknown title";
    const artist = current.trackArtist || current.trackAlbumArtist;
    return artist ? title + " — " + artist : title;
  }

  function choose() {
    if (media.player)
      media.chosenAddress = media.player.dbusName;
  }

  function toggle() {
    const current = media.player;
    if (!current)
      return;
    media.choose();
    current.togglePlaying();
  }

  function next() {
    const current = media.player;
    if (current && current.canGoNext) {
      media.choose();
      current.next();
    }
  }

  function previous() {
    const current = media.player;
    if (current && current.canGoPrevious) {
      media.choose();
      current.previous();
    }
  }

  function seek(seconds) {
    const current = media.player;
    if (current && current.canSeek)
      current.position = Math.max(0, Math.min(current.length, seconds));
  }

  Timer {
    interval: 1000
    repeat: true
    running: media.playing
    onTriggered: {
      media.positionTick++;
      if (media.player)
        media.player.positionChanged();
    }
  }
}
