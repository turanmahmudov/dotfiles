pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property int cpu: 0
  property int mem: 0
  property int temp: 0
  property real memUsedGb: 0
  property real memTotalGb: 0

  property string netIface: ""
  property real netDown: 0
  property real netUp: 0

  property int _prevIdle: 0
  property int _prevTotal: 0
  property real _prevRx: 0
  property real _prevTx: 0
  property real _prevUp: 0

  function toInt(s) {
    var n = parseInt(s)
    return isNaN(n) ? 0 : n
  }

  function readCpu(text) {
    var first = text.split("\n")[0]
    if (!first || first.indexOf("cpu ") !== 0)
      return
    var p = first.trim().split(/\s+/)
    var idle = root.toInt(p[4])
    var total = 0
    for (var i = 1; i < p.length; i++)
      total += root.toInt(p[i])
    var di = idle - root._prevIdle
    var dt = total - root._prevTotal
    if (dt > 0 && root._prevTotal > 0)
      root.cpu = Math.max(0, Math.min(100, Math.round(100 * (1 - di / dt))))
    root._prevIdle = idle
    root._prevTotal = total
  }

  function readMem(text) {
    var tot = 0, av = 0
    var lines = text.split("\n")
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].indexOf("MemTotal:") === 0)
        tot = root.toInt(lines[i].split(/\s+/)[1])
      else if (lines[i].indexOf("MemAvailable:") === 0)
        av = root.toInt(lines[i].split(/\s+/)[1])
    }
    if (tot > 0) {
      root.mem = Math.round((tot - av) * 100 / tot)
      root.memTotalGb = tot / 1048576
      root.memUsedGb = (tot - av) / 1048576
    }
  }

  function readNet(routeText, devText, up) {
    var iface = ""
    var rl = routeText.split("\n")
    for (var i = 1; i < rl.length; i++) {
      var f = rl[i].trim().split(/\s+/)
      if (f.length >= 2 && f[1] === "00000000") {
        iface = f[0]
        break
      }
    }
    root.netIface = iface
    if (!iface)
      return
    var curRx = -1, curTx = -1
    var dl = devText.split("\n")
    for (var j = 0; j < dl.length; j++) {
      var c = dl[j].replace(/:/g, " ").trim().split(/\s+/)
      if (c[0] === iface) {
        curRx = root.toInt(c[1])
        curTx = root.toInt(c[9])
        break
      }
    }
    if (curRx < 0)
      return
    if (up > 0 && root._prevUp > 0 && up > root._prevUp) {
      var span = up - root._prevUp
      root.netDown = Math.max(0, (curRx - root._prevRx) / span)
      root.netUp = Math.max(0, (curTx - root._prevTx) / span)
    }
    root._prevRx = curRx
    root._prevTx = curTx
  }

  function tick() {
    statFile.reload()
    root.readCpu(statFile.text())
    memFile.reload()
    root.readMem(memFile.text())
    if (String(tempFile.path).length > 0) {
      tempFile.reload()
      root.temp = Math.round(root.toInt(tempFile.text()) / 1000)
    }
    upFile.reload()
    var up = parseFloat(upFile.text()) || 0
    routeFile.reload()
    netDevFile.reload()
    root.readNet(routeFile.text(), netDevFile.text(), up)
    root._prevUp = up
  }

  property FileView statFile: FileView { path: "/proc/stat"; blockLoading: true; printErrors: false }
  property FileView memFile: FileView { path: "/proc/meminfo"; blockLoading: true; printErrors: false }
  property FileView upFile: FileView { path: "/proc/uptime"; blockLoading: true; printErrors: false }
  property FileView routeFile: FileView { path: "/proc/net/route"; blockLoading: true; printErrors: false }
  property FileView netDevFile: FileView { path: "/proc/net/dev"; blockLoading: true; printErrors: false }
  property FileView tempFile: FileView { path: ""; blockLoading: true; printErrors: false }

  property Process tempPathProc: Process {
    command: ["sh", "-c", "for f in /sys/class/hwmon/hwmon*/temp1_input; do [ -f \"$f\" ] && { echo \"$f\"; break; }; done"]
    stdout: StdioCollector {
      onStreamFinished: {
        var p = text.trim()
        if (p)
          root.tempFile.path = p
      }
    }
  }

  property Timer poll: Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.tick()
  }

  Component.onCompleted: root.tempPathProc.running = true
}
