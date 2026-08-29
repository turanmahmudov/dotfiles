pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property var devices: []
  property var ruleByHash: ({})
  property bool primed: false
  property var blockedIds: ({})

  signal deviceBlocked(string name, int id)

  readonly property var entries: {
    var out = []
    for (var i = 0; i < devices.length; i++) {
      var device = devices[i]
      var ruleId = root.ruleByHash[device.hash]
      out.push({
        "id": device.id,
        "name": device.name,
        "vidpid": device.vidpid,
        "port": device.port,
        "blocked": device.blocked,
        "saved": ruleId !== undefined,
        "ruleId": ruleId === undefined ? -1 : ruleId
      })
    }
    return out
  }

  readonly property int blockedCount: {
    var n = 0
    for (var i = 0; i < devices.length; i++)
      if (devices[i].blocked)
        n++
    return n
  }

  function refresh() {
    rulesProc.running = true
    listProc.running = true
  }

  function allowOnce(id) {
    Quickshell.execDetached(["usbguard", "allow-device", String(id)])
  }

  function blockDevice(id) {
    Quickshell.execDetached(["usbguard", "block-device", String(id)])
  }

  // Writing or dropping a rule is a policy change, which the plugdev IPC grant
  // excludes. The DBus equivalents need auth_admin and no polkit agent answers
  // here, so both go through pkexec. pkexec refuses to serve a process whose
  // parent already exited, so these run attached rather than through
  // Quickshell.execDetached, which double-forks.
  function runPrivileged(args) {
    privilegedRunner.createObject(root, { "command": args })
  }

  function allowAlways(id) {
    root.runPrivileged(["pkexec", "usbguard", "allow-device", String(id), "-p"])
  }

  function forgetRule(ruleId) {
    root.runPrivileged(["pkexec", "usbguard", "remove-rule", String(ruleId)])
  }

  property Component privilegedRunner: Component {
    Process {
      id: proc
      running: true
      onExited: {
        root.refresh()
        Qt.callLater(proc.destroy)
      }
    }
  }

  function parseDeviceList(text) {
    var out = []
    var lines = String(text).split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i]
      var head = line.match(/^(\d+):\s+(\S+)\s+id\s+(\S+)\s/)
      if (!head)
        continue
      var port = line.match(/\svia-port "([^"]*)"/)
      if (port && /^usb\d+$/.test(port[1]))
        continue
      var name = line.match(/\sname "([^"]*)"/)
      var hash = line.match(/\shash "([^"]*)"/)
      out.push({
        "id": parseInt(head[1]),
        "blocked": head[2] !== "allow",
        "vidpid": head[3],
        "name": (name && name[1].length > 0) ? name[1] : head[3],
        "port": port ? port[1] : "",
        "hash": hash ? hash[1] : ""
      })
    }
    return out
  }

  function parseRuleList(text) {
    var out = ({})
    var lines = String(text).split("\n")
    for (var i = 0; i < lines.length; i++) {
      var head = lines[i].match(/^(\d+):\s+allow\s/)
      if (!head)
        continue
      var hash = lines[i].match(/\shash "([^"]*)"/)
      if (hash && out[hash[1]] === undefined)
        out[hash[1]] = parseInt(head[1])
    }
    return out
  }

  function applyDeviceList(next) {
    var seen = {}
    for (var i = 0; i < next.length; i++) {
      var device = next[i]
      if (!device.blocked)
        continue
      seen[device.id] = true
      if (root.primed && !root.blockedIds[device.id])
        root.deviceBlocked(device.name, device.id)
    }
    root.blockedIds = seen
    root.devices = next
    root.primed = true
  }

  property Process listProc: Process {
    command: ["usbguard", "list-devices"]
    stdout: StdioCollector {
      onStreamFinished: root.applyDeviceList(root.parseDeviceList(text))
    }
  }

  property Process rulesProc: Process {
    command: ["usbguard", "list-rules"]
    stdout: StdioCollector {
      onStreamFinished: root.ruleByHash = root.parseRuleList(text)
    }
  }

  // usbguard prints a header line then indented detail lines, and one plug
  // raises both a presence and a policy event, so collapse the burst.
  property Process watcher: Process {
    running: true
    command: ["usbguard", "watch"]
    stdout: SplitParser {
      onRead: (line) => {
        if (String(line).charAt(0) === "[")
          debounce.restart()
      }
    }
    onExited: revive.restart()
  }

  property Timer debounce: Timer {
    interval: 150
    onTriggered: root.refresh()
  }

  property Timer revive: Timer {
    interval: 3000
    onTriggered: root.watcher.running = true
  }

  property IpcHandler ipc: IpcHandler {
    target: "usbguard"
    function refresh(): string {
      root.refresh()
      return "ok"
    }
    function blocked(): string {
      return String(root.blockedCount)
    }
    function forget(ruleId: string): string {
      root.forgetRule(parseInt(ruleId))
      return "ok"
    }
    function always(deviceId: string): string {
      root.allowAlways(parseInt(deviceId))
      return "ok"
    }
  }
}
