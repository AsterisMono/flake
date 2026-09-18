pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
  id: audio

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var channel: audio.sink && audio.sink.audio ? audio.sink.audio : null

  readonly property bool available: Pipewire.ready && audio.sink !== null && audio.channel !== null
  readonly property real volume: audio.channel ? audio.channel.volume : 0
  readonly property bool muted: audio.channel ? audio.channel.muted : false

  readonly property var sinks: {
    const list = Pipewire.nodes.values;
    const result = [];
    for (let i = 0; i < list.length; i++) {
      const node = list[i];
      if (node.isSink && !node.isStream && node.audio)
        result.push(node);
    }
    return result;
  }

  readonly property string sinkName: {
    if (!audio.sink)
      return "";
    return audio.sink.description || audio.sink.nickname || audio.sink.name || "";
  }

  readonly property bool isHdmi: /hdmi|displayport|dp-/i.test(audio.sinkName)

  readonly property string indicatorIcon: {
    if (audio.muted)
      return audio.isHdmi ? "mutedHdmi" : "muted";
    return audio.isHdmi ? "volumeHdmi" : "volume";
  }

  function setVolume(value) {
    if (!audio.channel)
      return;
    audio.channel.volume = Math.max(0, Math.min(1.5, value));
  }

  function adjust(delta) {
    audio.setVolume(audio.volume + delta);
  }

  function toggleMute() {
    if (!audio.channel)
      return;
    audio.channel.muted = !audio.channel.muted;
  }

  function setDefaultSink(node) {
    if (node)
      Pipewire.preferredDefaultAudioSink = node;
  }

  // Binding the default sink makes its mutable audio properties available.
  PwObjectTracker {
    objects: [audio.sink]
  }
}
