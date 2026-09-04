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

  // Evaluated once per Pipewire change and shared by every consumer. Calling
  // the filters from each binding instead rebuilds the lists per call site, and
  // a new array tears down and recreates every delegate that reads it.
  readonly property var sinks: root.filterNodes(true)
  readonly property var sources: root.filterNodes(false)
  readonly property var playbackStreams: root.filterStreams("Stream/Output/Audio")
  readonly property var recordStreams: root.filterStreams("Stream/Input/Audio")

  function filterStreams(mediaClass) {
    var out = []
    var nodes = Pipewire.nodes ? Pipewire.nodes.values : []
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i]
      if (n && n.audio && n.isStream && root.nodeProperty(n, "media.class") === mediaClass)
        out.push(n)
    }
    return out
  }

  function nodeProperty(node, key) {
    var props = node ? node.properties : null
    return (props && props[key] !== undefined) ? String(props[key]) : ""
  }

  function resolveStreamLabel(node) {
    var name = root.nodeProperty(node, "application.name")
    if (name.length === 0)
      name = root.nodeProperty(node, "application.process.binary")
    if (name.length === 0)
      name = node ? String(node.name || "") : ""
    return name.length > 0 ? name : "Stream"
  }

  function resolveStreamTitle(node) {
    return root.nodeProperty(node, "media.name")
  }

  // A stream carries no target of its own; the link to the device is what says
  // where it plays or records.
  function resolveStreamDevice(node) {
    if (!node)
      return null
    var groups = Pipewire.linkGroups ? Pipewire.linkGroups.values : []
    for (var i = 0; i < groups.length; i++) {
      var g = groups[i]
      if (g.source && node.id === g.source.id)
        return g.target
      if (g.target && node.id === g.target.id)
        return g.source
    }
    return null
  }

  function moveStream(node, device) {
    var serial = root.nodeProperty(node, "object.serial")
    if (!device || serial.length === 0)
      return
    var verb = node.isSink ? "move-sink-input" : "move-source-output"
    Quickshell.execDetached(["pactl", verb, serial, String(device.name)])
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
      var nodes = Pipewire.nodes ? Pipewire.nodes.values : []
      for (var i = 0; i < nodes.length; i++)
        if (nodes[i] && nodes[i].audio && nodes[i].isStream)
          arr.push(nodes[i])
      return arr
    }
  }
}
