pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QtObject {
  id: root

  readonly property var toplevels: Hyprland.toplevels
  readonly property var workspaces: Hyprland.workspaces
  readonly property var monitors: Hyprland.monitors
  readonly property var focusedMonitor: Hyprland.focusedMonitor
  readonly property var focusedWorkspace: Hyprland.focusedWorkspace

  // The ShellScreen the compositor considers focused, for windows that should
  // follow the user rather than sit on the primary output.
  readonly property var focusedScreen: {
    var name = Hyprland.focusedMonitor ? String(Hyprland.focusedMonitor.name) : ""
    var screens = Quickshell.screens
    for (var i = 0; i < screens.length; i++)
      if (screens[i].name === name)
        return screens[i]
    return screens.length > 0 ? screens[0] : null
  }

  property string kbLayoutFull: ""
  property string kbLayout: "??"
  property int revision: 0

  function focusWorkspace(selector) {
    var target = (typeof selector === "number") ? String(selector) : "\"" + String(selector) + "\""
    Hyprland.dispatch("hl.dsp.focus({ workspace = " + target + " })")
  }

  function toggleSpecialWorkspace(key) {
    Hyprland.dispatch("hl.dsp.workspace.toggle_special(\"" + String(key || "special") + "\")")
  }

  function monitorFor(screen) {
    return Hyprland.monitorFor(screen)
  }

  function refreshToplevels() {
    Hyprland.refreshToplevels()
  }

  function refreshWorkspaces() {
    Hyprland.refreshWorkspaces()
  }

  function refreshMonitors() {
    Hyprland.refreshMonitors()
  }

  function isSpecialName(name) {
    return String(name || "").indexOf("special:") === 0
  }

  function specialKey(name) {
    var n = String(name || "")
    if (n.indexOf("special:") === 0)
      return n.substring(8)
    return n.length > 0 ? n : "special"
  }

  function activeSpecialName(monitor) {
    if (!monitor)
      return ""
    var ipc = monitor.lastIpcObject
    if (ipc && ipc.specialWorkspace && ipc.specialWorkspace.name)
      return String(ipc.specialWorkspace.name)
    var sw = monitor.specialWorkspace
    if (sw && sw.name)
      return String(sw.name)
    return ""
  }

  function hasFullscreen() {
    var mons = Hyprland.monitors ? Hyprland.monitors.values : []
    for (var i = 0; i < mons.length; i++) {
      var m = mons[i]
      if (!m || !m.activeWorkspace)
        continue
      var tls = m.activeWorkspace.toplevels ? m.activeWorkspace.toplevels.values : []
      for (var j = 0; j < tls.length; j++) {
        var t = tls[j]
        if (!t)
          continue
        var ipc = t.lastIpcObject
        if (ipc && ipc.fullscreen > 1)
          return true
        if (t.fullscreen && t.fullscreen !== 0)
          return true
      }
    }
    return false
  }

  function toplevelClass(t) {
    if (!t)
      return ""
    var ipc = t.lastIpcObject
    if (ipc && ipc.class)
      return String(ipc.class)
    if (t.wayland && t.wayland.appId)
      return String(t.wayland.appId)
    return ""
  }

  function windowsByWorkspace() {
    var tls = Hyprland.toplevels ? Hyprland.toplevels.values : []
    var m = ({})
    for (var i = 0; i < tls.length; i++) {
      var t = tls[i]
      if (!t || !t.workspace)
        continue
      var id = String(t.workspace.id)
      var cls = root.toplevelClass(t)
      if (!cls)
        continue
      if (!m[id])
        m[id] = ({})
      m[id][cls] = true
    }
    return m
  }

  function urgentWorkspaceIds() {
    var tls = Hyprland.toplevels ? Hyprland.toplevels.values : []
    var out = ({})
    for (var i = 0; i < tls.length; i++) {
      var t = tls[i]
      if (t && t.urgent && t.workspace)
        out[t.workspace.id] = true
    }
    return out
  }

  function shortLayout(full) {
    var s = String(full || "")
    if (!s)
      return "??"
    if (/german|deutsch/i.test(s))
      return "DE"
    if (/turkish|türk/i.test(s))
      return "TR"
    if (/us|english \(us\)|english/i.test(s))
      return "US"
    var m = s.match(/\(([A-Za-z]{2})\)/)
    if (m)
      return m[1].toUpperCase()
    return s.substring(0, 2).toUpperCase()
  }

  function refreshDevices() {
    kbProc.running = true
  }

  function handleEvent(event) {
    if (!event)
      return
    var n = String(event.name || "")
    if (n.indexOf("v2") === n.length - 2 && n.length > 2)
      return

    if (n === "activelayout") {
      root.refreshDevices()
      return
    }

    if (n === "workspace" || n === "moveworkspace" || n === "activespecial" || n === "focusedmon") {
      Hyprland.refreshWorkspaces()
      Hyprland.refreshMonitors()
    } else if (n === "openwindow" || n === "closewindow" || n === "movewindow") {
      Hyprland.refreshToplevels()
      Hyprland.refreshWorkspaces()
    } else if (n.indexOf("mon") !== -1) {
      Hyprland.refreshMonitors()
    } else if (n.indexOf("workspace") !== -1) {
      Hyprland.refreshWorkspaces()
    } else if (n.indexOf("window") !== -1 || n.indexOf("group") !== -1
               || n === "pin" || n === "fullscreen" || n === "changefloatingmode" || n === "minimize") {
      Hyprland.refreshToplevels()
    }
    root.revision = root.revision + 1
  }

  property Process kbProc: Process {
    command: ["sh", "-c", "hyprctl -j devices 2>/dev/null | jq -r '.keyboards[] | select(.main==true) | .active_keymap' | head -1"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.kbLayoutFull = text.trim()
        root.kbLayout = root.shortLayout(root.kbLayoutFull)
      }
    }
  }

  property Connections hyprConn: Connections {
    target: Hyprland
    function onRawEvent(event) {
      root.handleEvent(event)
    }
  }

  Component.onCompleted: root.refreshDevices()
}
