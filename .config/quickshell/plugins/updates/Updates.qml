pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  readonly property string home: Quickshell.env("HOME")
  property int count: 0
  property string tooltip: ""
  property bool hasUpdates: false

  function refresh() {
    proc.running = true
  }

  function parse(out) {
    try {
      var j = JSON.parse(out.trim() || "{}")
      root.tooltip = j.tooltip || ""
      root.hasUpdates = (j["class"] === "has-updates")
      var m = (j.tooltip || "").match(/^(\d+)/)
      root.count = m ? parseInt(m[1]) : 0
    } catch (e) {
      root.count = 0
      root.hasUpdates = false
    }
  }

  property Process proc: Process {
    command: ["sh", "-c", root.home + "/.local/bin/apt-updates 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: root.parse(text)
    }
  }

  property Timer poll: Timer {
    interval: 3600000
    running: true
    repeat: true
    onTriggered: root.proc.running = true
  }

  Component.onCompleted: proc.running = true
}
