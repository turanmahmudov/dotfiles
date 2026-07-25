pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

QtObject {
  id: root

  readonly property PwNode sinkNode: Pipewire.defaultAudioSink
  readonly property PwNode sourceNode: Pipewire.defaultAudioSource
  readonly property bool sinkReady: sinkNode && sinkNode.ready && sinkNode.audio
  readonly property bool sourceReady: sourceNode && sourceNode.ready && sourceNode.audio

  readonly property real volume: sinkReady ? sinkNode.audio.volume : 0
  readonly property bool muted: sinkReady ? sinkNode.audio.muted : false
  readonly property real micVolume: sourceReady ? sourceNode.audio.volume : 0
  readonly property bool micMuted: sourceReady ? sourceNode.audio.muted : false

  function setVolume(v) {
    if (sinkReady)
      sinkNode.audio.volume = Math.max(0, Math.min(1, v))
  }

  function changeVolume(delta) {
    setVolume(volume + delta)
  }

  function toggleMute() {
    if (sinkReady)
      sinkNode.audio.muted = !sinkNode.audio.muted
  }

  function setMicVolume(v) {
    if (sourceReady)
      sourceNode.audio.volume = Math.max(0, Math.min(1, v))
  }

  function toggleMicMute() {
    if (sourceReady)
      sourceNode.audio.muted = !sourceNode.audio.muted
  }

  function setDefaultSink(node) {
    if (node)
      Pipewire.preferredDefaultAudioSink = node
  }

  function setDefaultSource(node) {
    if (node)
      Pipewire.preferredDefaultAudioSource = node
  }

  function listSinks() {
    return filterNodes(true)
  }

  function listSources() {
    return filterNodes(false)
  }

  function filterNodes(wantSink) {
    var out = []
    var nodes = Pipewire.nodes ? Pipewire.nodes.values : []
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i]
      if (n && n.audio && n.isStream === false && n.isSink === wantSink)
        out.push(n)
    }
    return out
  }

  property PwObjectTracker tracker: PwObjectTracker {
    objects: {
      var arr = []
      if (root.sinkNode)
        arr.push(root.sinkNode)
      if (root.sourceNode)
        arr.push(root.sourceNode)
      return arr
    }
  }
}
