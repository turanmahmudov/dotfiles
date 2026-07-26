pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QtObject {
  id: root

  property bool active: false
  property string mode: "region"
  property bool recording: false
  property bool withAudio: false
  property int elapsed: 0
  property string lastPath: ""
  property string videosDir: Quickshell.env("HOME") + "/Videos"

  readonly property string elapsedLabel: {
    var m = Math.floor(root.elapsed / 60)
    var s = root.elapsed % 60
    return m + ":" + (s < 10 ? "0" + s : s)
  }

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

  function toggleAudio() {
    withAudio = !withAudio
  }

  function open(m) {
    if (recording)
      return
    mode = normalizeMode(m)
    Hyprland.refreshToplevels()
    active = true
  }

  function cancel() {
    active = false
  }

  function findMonitor(screenName) {
    var list = Hyprland.monitors.values
    for (var i = 0; i < list.length; i++)
      if (list[i].name === screenName)
        return list[i]
    return Hyprland.focusedMonitor
  }

  function buildPath() {
    var ts = Qt.formatDateTime(new Date(), "yyyy-MM-dd-HH-mm-ss")
    return videosDir + "/Recording_" + ts + ".mp4"
  }

  // Whole outputs are addressed by name so wf-recorder tracks the output rather
  // than a fixed rectangle; region and window become a geometry.
  function confirm(x, y, w, h, screenName) {
    if (recording)
      return
    if (mode !== "monitor" && (w < 1 || h < 1)) {
      cancel()
      return
    }
    var args = ["wf-recorder", "-y"]
    if (mode === "monitor") {
      args.push("-o", String(screenName))
    } else {
      var mon = findMonitor(screenName)
      var mx = (mon && mon.lastIpcObject) ? mon.lastIpcObject.x : 0
      var my = (mon && mon.lastIpcObject) ? mon.lastIpcObject.y : 0
      args.push("-g", Math.round(x + mx) + "," + Math.round(y + my)
        + " " + Math.round(w) + "x" + Math.round(h))
    }
    if (withAudio)
      args.push("-a")
    root.lastPath = buildPath()
    args.push("-f", root.lastPath)

    root.active = false
    root.elapsed = 0
    mkdirProc.command = ["mkdir", "-p", root.videosDir]
    mkdirProc.running = true
    recordProc.command = args
    recordProc.running = true
    root.recording = true
  }

  // wf-recorder needs SIGINT to write the trailer; killing it outright leaves an
  // unplayable file.
  function stop() {
    if (!recording)
      return
    recordProc.signal(2)
  }

  // Straight to recording the focused output, skipping the selection overlay.
  function startFocused() {
    if (recording)
      return
    var name = Hyprland.focusedMonitor ? String(Hyprland.focusedMonitor.name) : ""
    if (!name.length)
      return
    root.active = false
    root.mode = "monitor"
    confirm(0, 0, 0, 0, name)
  }

  function toggle() {
    if (recording)
      stop()
    else
      open(root.mode)
  }

  function sendNotification(ok) {
    if (ok)
      Quickshell.execDetached(["notify-send", "-a", "Recorder",
        "-h", "string:x-quickshell-open:" + root.lastPath,
        "Recording saved", root.lastPath])
    else
      Quickshell.execDetached(["notify-send", "-a", "Recorder", "-u", "critical",
        "Recording failed", "wf-recorder exited with an error"])
  }

  property Process mkdirProc: Process {}

  property Process recordProc: Process {
    onExited: (code) => {
      root.recording = false
      root.sendNotification(code === 0)
      root.elapsed = 0
    }
  }

  property Timer ticker: Timer {
    interval: 1000
    repeat: true
    running: root.recording
    onTriggered: root.elapsed = root.elapsed + 1
  }

  property Process dirProc: Process {
    command: ["xdg-user-dir", "VIDEOS"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var d = text.trim()
        if (d.length > 0)
          root.videosDir = d
      }
    }
  }

  property IpcHandler ipc: IpcHandler {
    target: "recorder"
    function open(mode: string): string {
      root.open(mode)
      return root.mode
    }
    function startFocused(): string {
      root.startFocused()
      return root.recording ? "recording" : "failed"
    }
    function cancel(): string {
      root.cancel()
      return "ok"
    }
    function stop(): string {
      root.stop()
      return "ok"
    }
    function toggle(): string {
      root.toggle()
      return root.recording ? "recording" : "idle"
    }
    function status(): string {
      return root.recording ? ("recording " + root.elapsedLabel) : "idle"
    }
  }
}
