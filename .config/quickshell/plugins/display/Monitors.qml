pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QtObject {
  id: root

  property var list: []
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

  readonly property int enabledCount: {
    var n = 0
    for (var i = 0; i < list.length; i++)
      if (!list[i].disabled)
        n++
    return n
  }

  function isInternal(name) {
    return /^(eDP|LVDS|DSI)/i.test(name)
  }

  function find(name) {
    for (var i = 0; i < list.length; i++)
      if (list[i].name === name)
        return list[i]
    return null
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

  function buildMonitorLua(m, x, y, scale) {
    var hz = m.refreshRaw > 0 ? m.refreshRaw.toFixed(2) : m.refreshRate
    return "hl.monitor({ output = \"" + m.name + "\", mode = \"" + m.width + "x" + m.height + "@" + hz
      + "\", position = \"" + x + "x" + y + "\", scale = " + scale + " })"
  }

  function setScale(name, scale) {
    var m = find(name)
    if (!m || m.disabled)
      return
    applyLayout(name, snapScale(m.width, m.height, scale))
  }

  function applyLayout(changedName, changedScale) {
    var mons = list.filter(function (m) {
      return !m.disabled
    })
    mons.sort(function (a, b) {
      return (a.x - b.x) || (a.y - b.y)
    })
    if (mons.length === 0)
      return
    var cx = mons[0].x
    var placed = []
    var grow = false
    for (var i = 0; i < mons.length; i++) {
      var m = mons[i]
      var sc = (m.name === changedName) ? changedScale : m.scale
      if (m.name === changedName)
        grow = Math.round(m.width / sc) > Math.round(m.width / m.scale)
      placed.push({ "m": m, "x": cx, "y": m.y, "scale": sc })
      cx += Math.round(m.width / sc)
    }
    var order = []
    for (var k = 0; k < placed.length; k++)
      order.push(grow ? placed.length - 1 - k : k)
    var cmds = []
    for (var oi = 0; oi < order.length; oi++) {
      var p = placed[order[oi]]
      if (p.x !== p.m.x || p.y !== p.m.y || Math.abs(p.scale - p.m.scale) > 1e-4)
        cmds.push(buildMonitorLua(p.m, p.x, p.y, p.scale))
    }
    if (cmds.length === 0)
      return
    runLua(cmds.join(" "))
  }

  // Hyprland merges monitor rules per output, so `disabled` sticks until it is
  // explicitly cleared; omitting it here leaves the output off forever.
  function setEnabled(name, on) {
    if (!on && enabledCount <= 1)
      return
    runLua(on
      ? "hl.monitor({ output = \"" + name + "\", mode = \"preferred\", position = \"auto\", scale = 1, disabled = false })"
      : "hl.monitor({ output = \"" + name + "\", disabled = true })")
  }

  function runLua(code) {
    setProc.command = ["hyprctl", "eval", code]
    setProc.running = true
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
          "internal": root.isInternal(m.name)
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

  property Process setProc: Process {
    onExited: {
      root.refresh()
      // hyprctl returns before the compositor has settled, so read again.
      root.refreshDebounce.restart()
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
