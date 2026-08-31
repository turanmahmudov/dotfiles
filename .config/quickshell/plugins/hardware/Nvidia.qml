pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  // "none" while no driver answers, "sleep" while the card is runtime suspended,
  // "ok" while a reading arrived.
  property string state: "none"
  readonly property bool present: root.state !== "none"
  readonly property bool awake: root.state === "ok"

  property string name: ""
  property string driver: ""
  property int util: 0
  property int memUtil: 0
  property int encUtil: 0
  property int decUtil: 0
  property int memUsedMb: 0
  property int memTotalMb: 0
  property int temp: 0
  property real powerDraw: -1
  property real powerLimit: -1
  property int clockSm: 0
  property int clockSmMax: 0
  property int clockMem: 0
  property int fan: -1
  property string pstate: ""
  property int linkGen: 0
  property int linkWidth: 0

  property var processes: []

  readonly property int memPercent: root.memTotalMb > 0
    ? Math.round(root.memUsedMb * 100 / root.memTotalMb) : 0

  function refresh() {
    root.statsProc.running = true
  }

  function refreshProcesses() {
    root.procProc.running = true
  }

  function toInt(s) {
    var n = parseInt(s)
    return isNaN(n) ? 0 : n
  }

  function toReal(s) {
    var n = parseFloat(s)
    return isNaN(n) ? -1 : n
  }

  function clear() {
    root.name = ""
    root.driver = ""
    root.util = 0
    root.memUtil = 0
    root.encUtil = 0
    root.decUtil = 0
    root.memUsedMb = 0
    root.memTotalMb = 0
    root.temp = 0
    root.powerDraw = -1
    root.powerLimit = -1
    root.clockSm = 0
    root.clockSmMax = 0
    root.clockMem = 0
    root.fan = -1
    root.pstate = ""
    root.linkGen = 0
    root.linkWidth = 0
    root.processes = []
  }

  function parseStats(out) {
    var lines = String(out).split("\n")
    var head = lines[0] ? lines[0].trim() : ""
    if (head !== "ok") {
      root.state = (head === "sleep") ? "sleep" : "none"
      root.clear()
      return
    }
    var f = (lines[1] || "").split(",")
    if (f.length < 18) {
      root.state = "none"
      root.clear()
      return
    }
    for (var i = 0; i < f.length; i++)
      f[i] = f[i].trim()
    root.state = "ok"
    root.name = f[0].replace(/^NVIDIA\s+/, "")
    root.driver = f[1]
    root.util = root.toInt(f[2])
    root.memUtil = root.toInt(f[3])
    root.encUtil = root.toInt(f[4])
    root.decUtil = root.toInt(f[5])
    root.memUsedMb = root.toInt(f[6])
    root.memTotalMb = root.toInt(f[7])
    root.temp = root.toInt(f[8])
    root.powerDraw = root.toReal(f[9])
    root.powerLimit = root.toReal(f[10])
    root.clockSm = root.toInt(f[11])
    root.clockSmMax = root.toInt(f[12])
    root.clockMem = root.toInt(f[13])
    root.fan = root.toReal(f[14])
    root.pstate = f[15]
    root.linkGen = root.toInt(f[16])
    root.linkWidth = root.toInt(f[17])
  }

  function parseProcesses(out) {
    var list = []
    var lines = String(out).split("\n")
    for (var i = 0; i < lines.length; i++) {
      var f = lines[i].split("|")
      if (f.length < 5 || f[0] !== "P")
        continue
      list.push({
        "pid": root.toInt(f[1]),
        "kind": f[2],
        "name": f[3],
        "memMb": root.toInt(f[4])
      })
    }
    list.sort(function (a, b) {
      return b.memMb - a.memMb
    })
    root.processes = list
  }

  // A reading through nvidia-smi wakes a runtime suspended card, so the state of
  // the PCI device decides whether the card is asked at all.
  readonly property string probeScript: '
command -v nvidia-smi >/dev/null 2>&1 || { echo none; exit 0; }
st=""
for f in /sys/bus/pci/drivers/nvidia/0000:*/power/runtime_status; do
  [ -f "$f" ] || continue
  st=$(cat "$f" 2>/dev/null)
  break
done
[ "$st" = "suspended" ] && { echo sleep; exit 0; }
'

  property Process statsProc: Process {
    command: ["sh", "-c", root.probeScript + '
echo ok
nvidia-smi --query-gpu=name,driver_version,utilization.gpu,utilization.memory,utilization.encoder,utilization.decoder,memory.used,memory.total,temperature.gpu,power.draw,enforced.power.limit,clocks.sm,clocks.max.sm,clocks.mem,fan.speed,pstate,pcie.link.gen.current,pcie.link.width.current --format=csv,noheader,nounits 2>/dev/null | sed -n 1p
']
    stdout: StdioCollector {
      onStreamFinished: root.parseStats(text)
    }
  }

  property Process procProc: Process {
    command: ["sh", "-c", root.probeScript + '
nvidia-smi 2>/dev/null | sed -n "/Processes:/,\\$p" | grep -E "^\\| +[0-9]+ " | while read -r _b _g _gi _ci pid kind rest; do
  mem=$(echo "$rest" | awk "{print \\$(NF-1)}" | tr -dc "0-9")
  name=$(tr "\\0" "\\n" < /proc/$pid/cmdline 2>/dev/null | head -1)
  name=${name##*/}
  [ -n "$name" ] || name=$(cat /proc/$pid/comm 2>/dev/null)
  echo "P|$pid|$kind|$name|$mem"
done
']
    stdout: StdioCollector {
      onStreamFinished: root.parseProcesses(text)
    }
  }

  property Timer poll: Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
