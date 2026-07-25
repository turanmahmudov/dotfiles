pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property int value: 0
  property string device: "intel_backlight"
  property bool available: true

  function refresh() {
    getProc.running = true
  }

  function setPercent(p) {
    setProc.command = ["brightnessctl", "-d", device, "set", Math.max(1, Math.min(100, p)) + "%"]
    setProc.running = true
  }

  function changePercent(delta) {
    setPercent(value + delta)
  }

  property Process getProc: Process {
    command: ["sh", "-c", "brightnessctl -m -d " + root.device + " 2>/dev/null | cut -d, -f4 | tr -d '%'"]
    stdout: StdioCollector {
      onStreamFinished: {
        var v = parseInt(text.trim())
        if (!isNaN(v))
          root.value = v
        else
          root.available = false
      }
    }
  }

  property Process setProc: Process {
    onExited: root.refresh()
  }

  property FileView sysfsWatch: FileView {
    path: "/sys/class/backlight/" + root.device + "/brightness"
    watchChanges: true
    printErrors: false
    onFileChanged: {
      reload()
      root.refresh()
    }
    onLoaded: root.refresh()
  }

  property string kbdDevice: "tpacpi::kbd_backlight"
  property int kbdRaw: 0
  property int kbdMax: 1
  readonly property real kbdLevel: kbdMax > 0 ? kbdRaw / kbdMax : 0

  property FileView kbdWatch: FileView {
    path: "/sys/class/leds/" + root.kbdDevice + "/brightness"
    watchChanges: false
    printErrors: false
    onLoaded: root.kbdRaw = parseInt(text()) || 0
  }

  property FileView kbdMaxFile: FileView {
    path: "/sys/class/leds/" + root.kbdDevice + "/max_brightness"
    printErrors: false
    onLoaded: root.kbdMax = parseInt(text()) || 1
  }

  property Timer kbdPoll: Timer {
    interval: 500
    running: true
    repeat: true
    onTriggered: root.kbdWatch.reload()
  }

  Component.onCompleted: refresh()
}
