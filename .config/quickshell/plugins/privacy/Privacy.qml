pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

QtObject {
  id: root

  readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []

  // media.class is only populated for bound objects, so track the handful of
  // device-side video nodes rather than every node in the graph.
  readonly property var videoNodes: {
    var out = []
    for (var i = 0; i < nodes.length; i++)
      if (nodes[i] && !nodes[i].audio && !nodes[i].isStream)
        out.push(nodes[i])
    return out
  }

  property PwObjectTracker videoTracker: PwObjectTracker {
    objects: root.videoNodes
  }

  readonly property bool mic: {
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i]
      if (n && n.isStream && !n.isSink && n.audio)
        return true
    }
    return false
  }

  readonly property bool screen: {
    for (var i = 0; i < videoNodes.length; i++) {
      var n = videoNodes[i]
      if (!n || !n.properties)
        continue
      if (String(n.properties["media.class"] || "") !== "Video/Source")
        continue
      if (/xdg-desktop-portal|xdpw|screencast/i.test(String(n.properties["node.name"] || n.name || "")))
        return true
    }
    return false
  }

  property bool cam: false

  property Process camProc: Process {
    command: [Quickshell.env("HOME") + "/.local/bin/camera-in-use"]
    stdout: StdioCollector {
      onStreamFinished: root.cam = text.trim() === "1"
    }
  }

  property Timer camPoll: Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.camProc.running = true
  }
}
