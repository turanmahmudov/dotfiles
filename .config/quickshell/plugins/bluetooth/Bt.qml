pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Bluetooth

QtObject {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool powered: !!adapter && adapter.enabled
  readonly property bool scanning: !!adapter && adapter.discovering

  readonly property var devices: {
    var all = Bluetooth.devices ? Bluetooth.devices.values : []
    var out = []
    for (var i = 0; i < all.length; i++)
      if (all[i])
        out.push(all[i])
    out.sort(function (a, b) {
      if (a.connected !== b.connected)
        return a.connected ? -1 : 1
      if (a.paired !== b.paired)
        return a.paired ? -1 : 1
      return String(a.name || "").localeCompare(String(b.name || ""))
    })
    return out
  }

  readonly property int connectedCount: {
    var n = 0
    for (var i = 0; i < devices.length; i++)
      if (devices[i].connected)
        n++
    return n
  }

  function togglePower() {
    if (adapter)
      adapter.enabled = !adapter.enabled
  }

  function scan() {
    if (!adapter || adapter.discovering)
      return
    adapter.discovering = true
    scanTimer.restart()
  }

  function activate(device) {
    if (!device)
      return
    if (device.connected)
      device.disconnect()
    else if (device.paired)
      device.connect()
    else
      device.pair()
  }

  function forget(device) {
    if (device)
      device.forget()
  }

  property Timer scanTimer: Timer {
    interval: 8000
    onTriggered: if (root.adapter) root.adapter.discovering = false
  }

  property IpcHandler ipc: IpcHandler {
    target: "bluetooth"
    function toggle(): string {
      root.togglePower()
      return "ok"
    }
    function scan(): string {
      root.scan()
      return "ok"
    }
  }
}
