pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QtObject {
  id: root

  property var list: []

  readonly property int activeCount: {
    var n = 0
    for (var i = 0; i < list.length; i++)
      if (!list[i].disabled)
        n = n + 1
    return n
  }
  property var ddcByName: ({})

  function hasDdc(name) {
    return !!ddcByName[name] && ddcByName[name].brightness >= 0
  }

  function ddcBrightness(name) {
    return ddcByName[name] ? ddcByName[name].brightness : -1
  }

  function detectDdc() {
    ddcProc.running = true
  }

  function parseDdc(text) {
    var lines = text.split("\n")
    var map = ({})
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i])
        continue
      var f = lines[i].split("\t")
      if (f.length < 3)
        continue
      var b = parseInt(f[2])
      map[f[0]] = { "bus": parseInt(f[1]), "brightness": isNaN(b) ? -1 : b }
    }
    root.ddcByName = map
  }

  function setDdcBrightness(name, val) {
    var d = ddcByName[name]
    if (!d)
      return
    var v = Math.max(0, Math.min(100, Math.round(val)))
    Quickshell.execDetached(["ddcutil", "setvcp", "10", String(v), "--bus", String(d.bus)])
  }

  function isInternal(name) {
    return /^(eDP|LVDS|DSI)/i.test(name)
  }

  function refresh() {
    getProc.running = true
  }

  function snapScale(w, h, target) {
    if (w <= 0 || h <= 0)
      return target
    var best = -1
    var bestErr = 1e9
    var lo = Math.max(12, Math.round((target - 0.5) * 120))
    var hi = Math.round((target + 0.5) * 120)
    for (var q = lo; q <= hi; q++) {
      var s = q / 120
      var lw = w / s
      var lh = h / s
      if (Math.abs(lw - Math.round(lw)) < 1e-3 && Math.abs(lh - Math.round(lh)) < 1e-3) {
        var err = Math.abs(s - target)
        if (err < bestErr) {
          bestErr = err
          best = s
        }
      }
    }
    return best > 0 ? best : target
  }

  function parse(text) {
    try {
      var raw = JSON.parse(text)
      var out = []
      for (var i = 0; i < raw.length; i++) {
        var m = raw[i]
        out.push({
          "name": m.name,
          "description": m.description || "",
          "width": m.width || 0,
          "height": m.height || 0,
          "refreshRate": m.refreshRate ? Math.round(m.refreshRate) : 0,
          "refreshRaw": m.refreshRate || 0,
          "scale": m.scale || 1,
          "x": m.x || 0,
          "y": m.y || 0,
          "focused": !!m.focused,
          "disabled": !!m.disabled,
          "internal": root.isInternal(m.name),
          "transform": m.transform || 0,
          "availableModes": m.availableModes || [],
          "vrr": !!m.vrr,
          "mirrorOf": String(m.mirrorOf || "none"),
          "format": String(m.currentFormat || "")
        })
      }
      root.list = out
    } catch (e) {
    }
  }

  property Process getProc: Process {
    command: ["hyprctl", "-j", "monitors", "all"]
    stdout: StdioCollector {
      onStreamFinished: root.parse(text)
    }
  }

  property Process ddcProc: Process {
    command: ["sh", "-c",
      "ddcutil detect --brief 2>/dev/null | awk '/I2C bus:/{n=$0;sub(/.*i2c-/,\"\",n);bus=n} /DRM connector:/{c=$0;sub(/.*card[0-9]*-/,\"\",c);gsub(/[ \\t]/,\"\",c);if(bus!=\"\"){print c,bus;bus=\"\"}}' | while read conn busnum; do b=$(ddcutil getvcp 10 --bus \"$busnum\" --brief 2>/dev/null | awk '{print $4}'); printf '%s\\t%s\\t%s\\n' \"$conn\" \"$busnum\" \"$b\"; done"]
    stdout: StdioCollector {
      onStreamFinished: root.parseDdc(text)
    }
  }

  function affectsMonitors(name) {
    var n = String(name || "")
    return n.indexOf("monitor") === 0 || n === "focusedmon" || n === "configreloaded"
  }

  property Timer refreshDebounce: Timer {
    interval: 150
    onTriggered: root.refresh()
  }

  property Connections hyprEvents: Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (root.affectsMonitors(event ? event.name : ""))
        root.refreshDebounce.restart()
    }
  }

  Component.onCompleted: refresh()
}
