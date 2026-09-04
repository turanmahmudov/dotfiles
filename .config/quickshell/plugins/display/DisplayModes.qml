pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property bool visible: false
  property int toastMs: 1600

  readonly property var modes: {
    Monitors.list
    MonitorLayout.turnedOff
    var names = MonitorLayout.resolveOrder()
    var internals = []
    var externals = []
    for (var i = 0; i < names.length; i++) {
      if (Monitors.isInternal(names[i]))
        internals.push(names[i])
      else
        externals.push(names[i])
    }
    var out = []
    if (names.length < 2)
      return out
    out.push({ "key": "extend", "label": "Join", "icon": "columns-2", "off": [], "mirror": false, "cycle": true })
    if (internals.length > 0 && externals.length > 0) {
      out.push({ "key": "internal", "label": "Built-in", "icon": "laptop-minimal", "off": externals, "mirror": false, "cycle": true })
      out.push({ "key": "external", "label": "External", "icon": "monitor", "off": internals, "mirror": false, "cycle": true })
    }
    // Out of the cycle on purpose. Mirroring re-creates the mirrored output at
    // a new size, and Wayland clients that were on it can die with it, so it
    // stays a deliberate choice.
    out.push({ "key": "mirror", "label": "Mirror", "icon": "copy", "off": [], "mirror": true, "cycle": false })
    return out
  }

  readonly property string current: {
    var list = root.modes
    if (list.length === 0)
      return ""
    if (MonitorLayout.mirror)
      return "mirror"
    var names = MonitorLayout.resolveOrder()
    var off = []
    for (var i = 0; i < names.length; i++)
      if (!MonitorLayout.isEnabled(names[i]))
        off.push(names[i])
    for (var j = 0; j < list.length; j++)
      if (!list[j].mirror && root.matchesOff(list[j].off, off))
        return list[j].key
    return ""
  }

  function listCycleModes() {
    var list = root.modes
    var out = []
    for (var i = 0; i < list.length; i++)
      if (list[i].cycle)
        out.push(list[i])
    return out
  }

  function matchesOff(wanted, actual) {
    if (wanted.length !== actual.length)
      return false
    for (var i = 0; i < wanted.length; i++)
      if (actual.indexOf(wanted[i]) < 0)
        return false
    return true
  }

  function findMode(key) {
    var list = root.modes
    for (var i = 0; i < list.length; i++)
      if (list[i].key === key)
        return list[i]
    return null
  }

  function applyMode(key) {
    var mode = root.findMode(key)
    if (!mode)
      return false
    MonitorLayout.setIntent(mode.off, mode.mirror)
    return true
  }

  function show() {
    root.visible = true
    hideTimer.restart()
  }

  // A tap while mirroring lands on the first mode in the cycle, which turns
  // mirroring off again.
  function tap() {
    var list = root.listCycleModes()
    if (list.length < 2)
      return
    var at = -1
    for (var i = 0; i < list.length; i++)
      if (list[i].key === root.current)
        at = i
    root.applyMode(list[(at + 1) % list.length].key)
    root.show()
  }

  function pick(key) {
    if (root.applyMode(key))
      root.show()
  }

  property Timer hideTimer: Timer {
    interval: root.toastMs
    onTriggered: root.visible = false
  }

  property IpcHandler ipc: IpcHandler {
    target: "display"

    function tap(): string {
      root.tap()
      return root.current
    }

    function setMode(mode: string): string {
      return root.applyMode(mode) ? mode : "unknown"
    }

    function mode(): string {
      return root.current
    }
  }
}
