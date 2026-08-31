pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  readonly property var modes: ["nvidia", "on-demand", "intel"]

  // "nvidia", "on-demand" or "intel" while prime-select answers, empty while it
  // is absent.
  property string mode: ""
  property string pendingMode: ""
  readonly property bool available: root.mode.length > 0
  readonly property bool logoutNeeded: root.pendingMode.length > 0 && root.pendingMode !== root.mode

  function resolveLabel(mode) {
    if (mode === "nvidia")
      return "NVIDIA"
    if (mode === "intel")
      return "Integrated"
    return "On demand"
  }

  function resolveIcon(mode) {
    if (mode === "intel")
      return "cpu"
    if (mode === "nvidia")
      return "zap"
    return "gpu"
  }

  function refresh() {
    root.queryProc.running = true
  }

  // pkexec refuses to serve a process whose parent already exited, so the switch
  // runs attached rather than through Quickshell.execDetached, which double-forks.
  function selectMode(mode) {
    if (mode === root.mode || root.modes.indexOf(mode) < 0)
      return
    root.pendingMode = mode
    root.switchRunner.createObject(root, { "command": ["pkexec", "prime-select", mode] })
  }

  property Component switchRunner: Component {
    Process {
      id: proc
      running: true
      onExited: (code) => {
        if (code !== 0)
          root.pendingMode = ""
        root.refresh()
        Qt.callLater(proc.destroy)
      }
    }
  }

  property Process queryProc: Process {
    command: ["sh", "-c",
      'command -v prime-select >/dev/null 2>&1 || exit 0; prime-select query 2>/dev/null']
    stdout: StdioCollector {
      onStreamFinished: {
        var mode = String(text).trim()
        root.mode = root.modes.indexOf(mode) >= 0 ? mode : ""
        if (root.pendingMode === root.mode)
          root.pendingMode = ""
      }
    }
  }

  Component.onCompleted: root.refresh()
}
