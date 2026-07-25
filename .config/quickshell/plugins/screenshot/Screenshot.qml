pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Services

QtObject {
  id: root

  readonly property var delaySteps: [0, 3, 5, 10]
  readonly property int settleMs: 120

  property bool active: false
  property string mode: "region"
  property int delaySeconds: 0
  property bool capturing: false
  property int countdown: 0
  property string pendingGeometry: ""
  property string lastPath: ""
  property string picturesDir: Quickshell.env("HOME") + "/Pictures"

  function normalizeMode(m) {
    if (m === "window" || m === "monitor" || m === "region")
      return m
    return "region"
  }

  function setMode(m) {
    mode = normalizeMode(m)
    if (mode === "window")
      Hyprland.refreshToplevels()
  }

  function cycleDelay() {
    var i = delaySteps.indexOf(delaySeconds)
    delaySeconds = delaySteps[(i + 1) % delaySteps.length]
    return delaySeconds
  }

  function buildGrimGeometry(x, y, w, h, mx, my) {
    return Math.round(x + mx) + "," + Math.round(y + my)
      + " " + Math.round(w) + "x" + Math.round(h)
  }

  function findMonitor(screenName) {
    var list = Hyprland.monitors.values
    for (var i = 0; i < list.length; i++)
      if (list[i].name === screenName)
        return list[i]
    return Hyprland.focusedMonitor
  }

  function open(m) {
    mode = normalizeMode(m)
    delaySeconds = 0
    countdown = 0
    capturing = false
    Hyprland.refreshToplevels()
    active = true
  }

  function cancel() {
    active = false
    capturing = false
    countdown = 0
  }

  function grabScreen() {
    var sc = Hypr.focusedScreen
    if (!sc)
      return
    active = false
    delaySeconds = 0
    confirm(0, 0, sc.width, sc.height, sc.name)
  }

  function confirm(x, y, w, h, screenName) {
    if (w < 1 || h < 1) {
      cancel()
      return
    }
    var mon = findMonitor(screenName)
    var mx = (mon && mon.lastIpcObject) ? mon.lastIpcObject.x : 0
    var my = (mon && mon.lastIpcObject) ? mon.lastIpcObject.y : 0
    pendingGeometry = buildGrimGeometry(x, y, w, h, mx, my)
    capturing = true
    Qt.callLater(function () { root.active = false })
    if (delaySeconds > 0) {
      countdown = delaySeconds
      countdownTimer.restart()
    } else {
      settleTimer.restart()
    }
  }

  function shellQuote(s) {
    return "'" + String(s).replace(/'/g, "'\\''") + "'"
  }

  function runCapture() {
    var ts = Qt.formatDateTime(new Date(), "yyyy-MM-dd-HH-mm-ss")
    lastPath = picturesDir + "/Screenshot_" + ts + ".png"
    var f = shellQuote(lastPath)
    var d = shellQuote(picturesDir)
    var g = shellQuote(pendingGeometry)
    captureProc.command = ["sh", "-c",
      "mkdir -p " + d + " && grim -g " + g + " " + f + " && wl-copy --type image/png < " + f]
    captureProc.running = true
  }

  function sendNotification() {
    Quickshell.execDetached(["notify-send", "-a", "Screenshot",
      "-i", lastPath,
      "-h", "string:x-quickshell-open:" + lastPath,
      "Screenshot saved",
      "Saved to " + picturesDir + " and copied to clipboard"])
  }

  property Timer countdownTimer: Timer {
    interval: 1000
    repeat: true
    onTriggered: {
      root.countdown -= 1
      if (root.countdown <= 0) {
        stop()
        root.settleTimer.restart()
      }
    }
  }

  property Timer settleTimer: Timer {
    interval: root.settleMs
    repeat: false
    onTriggered: root.runCapture()
  }

  property Process captureProc: Process {
    running: false
    onExited: (code) => {
      root.capturing = false
      root.countdown = 0
      if (code === 0)
        root.sendNotification()
      else
        console.warn("Screenshot: capture failed with code", code)
    }
  }

  property Process dirProc: Process {
    command: ["xdg-user-dir", "PICTURES"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var d = text.trim()
        if (d && d.length > 0)
          root.picturesDir = d
      }
    }
  }

  property IpcHandler ipc: IpcHandler {
    target: "screenshot"
    function open(mode: string): string {
      root.open(mode)
      return root.mode
    }
    function grabScreen(): string {
      root.grabScreen()
      return "ok"
    }
    function cancel(): string {
      root.cancel()
      return "ok"
    }
  }
}
