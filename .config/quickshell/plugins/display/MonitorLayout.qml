pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

QtObject {
  id: root

  readonly property string path: Quickshell.env("HOME") + "/.config/hypr/monitors_generated.lua"

  property var order: []
  property var turnedOff: []
  property var outputs: ({})
  property bool mirror: false
  property int revision: 0
  property string applied: ""

  function resolveOrder() {
    root.revision
    var known = ({})
    var out = []
    for (var i = 0; i < root.order.length; i++)
      known[root.order[i]] = true
    for (var j = 0; j < root.order.length; j++)
      if (root.findMonitor(root.order[j]))
        out.push(root.order[j])
    var list = Monitors.list.slice()
    list.sort(function (a, b) {
      if (a.disabled !== b.disabled)
        return a.disabled ? 1 : -1
      return a.x - b.x
    })
    for (var k = 0; k < list.length; k++)
      if (!known[list[k].name])
        out.push(list[k].name)
    return out
  }

  function findMonitor(name) {
    var list = Monitors.list
    for (var i = 0; i < list.length; i++)
      if (list[i].name === name)
        return list[i]
    return null
  }

  function moveTo(name, index) {
    var current = root.resolveOrder()
    var from = current.indexOf(name)
    if (from < 0 || index < 0 || index >= current.length || from === index)
      return
    current.splice(from, 1)
    current.splice(index, 0, name)
    for (var i = 0; i < root.order.length; i++)
      if (current.indexOf(root.order[i]) < 0)
        current.push(root.order[i])
    root.order = current
    root.revision = root.revision + 1
    root.apply()
  }

  function isTurnedOff(name) {
    return root.turnedOff.indexOf(name) >= 0
  }

  // The user intent, limited to what is connected now. An intent that would
  // leave no output on falls back to the internal panel, so unplugging the
  // last external display never ends in a black screen.
  function resolveEnabledNames() {
    var names = root.resolveOrder()
    var out = []
    for (var i = 0; i < names.length; i++)
      if (!root.isTurnedOff(names[i]))
        out.push(names[i])
    if (out.length > 0)
      return out
    return root.resolveFallbackNames(names)
  }

  function resolveFallbackNames(names) {
    for (var i = 0; i < names.length; i++)
      if (Monitors.isInternal(names[i]))
        return [names[i]]
    return names.length > 0 ? [names[0]] : []
  }

  function isEnabled(name) {
    return root.resolveEnabledNames().indexOf(name) >= 0
  }

  function parseMode(text) {
    var m = String(text).match(/^(\d+)x(\d+)@([\d.]+)/)
    if (!m)
      return null
    return { "width": parseInt(m[1]), "height": parseInt(m[2]), "refresh": parseFloat(m[3]) }
  }

  function formatMode(monitor) {
    return monitor.width + "x" + monitor.height + "@" + monitor.refreshRaw.toFixed(2)
  }

  function hasLiveGeometry(monitor) {
    return !!monitor && monitor.width > 0 && monitor.height > 0 && monitor.scale > 0
  }

  function cloneOutputs() {
    var next = ({})
    for (var name in root.outputs) {
      var entry = ({})
      for (var field in root.outputs[name])
        entry[field] = root.outputs[name][field]
      next[name] = entry
    }
    return next
  }

  function storeSetting(name, field, value) {
    var next = root.cloneOutputs()
    if (!next[name])
      next[name] = ({})
    next[name][field] = value
    root.outputs = next
  }

  // A disabled output reports zeroed geometry, so the settings of an output are
  // remembered while it is on. Without this, turning it back on would adopt
  // whatever Hyprland picked and overwrite the mode and scale the user chose.
  function seedFromLive() {
    var list = Monitors.list
    if (root.order.length === 0 && Monitors.activeCount > 0)
      root.order = root.resolveOrder()
    var next = root.cloneOutputs()
    var changed = false
    for (var i = 0; i < list.length; i++) {
      var m = list[i]
      if (m.disabled || !root.hasLiveGeometry(m))
        continue
      if (!next[m.name])
        next[m.name] = ({})
      var entry = next[m.name]
      if (entry.mode === undefined) {
        entry.mode = root.formatMode(m)
        changed = true
      }
      if (entry.scale === undefined) {
        entry.scale = m.scale
        changed = true
      }
      if (entry.transform === undefined) {
        entry.transform = m.transform || 0
        changed = true
      }
    }
    if (changed)
      root.outputs = next
  }

  // A stored mode belongs to the display that was on this connector. Another
  // display may not have it, and Hyprland then falls back on its own.
  function resolveUsableMode(monitor, wanted) {
    var modes = monitor ? (monitor.availableModes || []) : []
    if (modes.length === 0)
      return wanted
    for (var i = 0; i < modes.length; i++) {
      var parsed = root.parseMode(modes[i])
      if (!parsed)
        continue
      if (parsed.width + "x" + parsed.height + "@" + parsed.refresh.toFixed(2) === wanted)
        return wanted
    }
    return root.hasLiveGeometry(monitor) ? root.formatMode(monitor) : ""
  }

  function resolveSettings(name) {
    var m = root.findMonitor(name)
    var stored = root.outputs[name] || ({})

    var mode = stored.mode
    if (mode !== undefined && m)
      mode = root.resolveUsableMode(m, mode)
    if ((mode === undefined || String(mode).length === 0) && root.hasLiveGeometry(m))
      mode = root.formatMode(m)

    var scale = stored.scale
    if (scale === undefined && root.hasLiveGeometry(m))
      scale = m.scale

    var transform = stored.transform
    if (transform === undefined)
      transform = (m && m.transform) ? m.transform : 0

    var parsed = (mode !== undefined && String(mode).length > 0) ? root.parseMode(mode) : null
    var known = parsed !== null && scale !== undefined && scale > 0

    return {
      "modeLiteral": known ? ("\"" + mode + "\"") : "\"preferred\"",
      "scaleLiteral": known ? String(Math.round(scale * 10000) / 10000) : "\"auto\"",
      "transform": transform,
      "logicalWidth": known ? Math.round(parsed.width / scale) : -1
    }
  }

  function buildRule(monitor, settings, positionLiteral, mirrorSource) {
    var bitdepth = String(monitor.format).indexOf("2101010") >= 0 ? 10 : 8
    return "hl.monitor({ output = \"" + monitor.name + "\", mode = " + settings.modeLiteral
      + (mirrorSource.length > 0
        ? (", mirror = \"" + mirrorSource + "\"")
        : (", position = " + positionLiteral))
      + ", scale = " + settings.scaleLiteral
      + ", bitdepth = " + bitdepth
      + (settings.transform ? (", transform = " + settings.transform) : "")
      + ", disabled = false })"
  }

  // Hyprland merges monitor rules per output, so `disabled` sticks until it is
  // explicitly cleared; omitting it here leaves the output off forever.
  function buildLines() {
    var names = root.resolveOrder()
    var enabledNames = root.resolveEnabledNames()
    var mirrorSource = (root.mirror && enabledNames.length > 1) ? enabledNames[0] : ""

    var settingsByName = ({})
    var exact = true
    for (var i = 0; i < enabledNames.length; i++) {
      var settings = root.resolveSettings(enabledNames[i])
      settingsByName[enabledNames[i]] = settings
      if (settings.logicalWidth < 0)
        exact = false
    }

    var x = 0
    var lines = []
    for (var j = 0; j < names.length; j++) {
      var m = root.findMonitor(names[j])
      if (!m)
        continue
      if (enabledNames.indexOf(names[j]) < 0) {
        lines.push({
          "name": m.name,
          "enabled": false,
          "mirrorSource": "",
          "position": -1,
          "settings": null,
          "code": "hl.monitor({ output = \"" + m.name + "\", disabled = true })"
        })
        continue
      }
      var own = settingsByName[names[j]]
      var mirrored = mirrorSource.length > 0 && m.name !== mirrorSource
      lines.push({
        "name": m.name,
        "enabled": true,
        "mirrorSource": mirrored ? mirrorSource : "",
        "position": exact ? x : -1,
        "settings": own,
        "code": root.buildRule(m, own, exact ? ("\"" + x + "x0\"") : "\"auto\"",
          mirrored ? mirrorSource : "")
      })
      if (!mirrored && exact)
        x += own.logicalWidth
    }
    return lines
  }

  function buildFile(lines) {
    return "------------------\n---- MONITORS ----\n------------------\n\n"
      + "-- Generated by the quickshell display panel. Manual edits are overwritten.\n"
      + "-- Outputs the user turned off are absent on purpose: the shell disables\n"
      + "-- them once it knows what is connected, so a boot without them stays usable.\n"
      + "-- See https://wiki.hypr.land/Configuring/Basics/Monitors/\n\n"
      + lines.join("\n") + "\n"
  }

  function evalLines(code) {
    if (String(code).length === 0)
      return
    applyProc.command = ["hyprctl", "eval", code]
    applyProc.running = true
    settleTimer.restart()
  }

  function matchesLive(line) {
    var m = root.findMonitor(line.name)
    if (!m)
      return false
    if (!line.enabled)
      return !!m.disabled
    if (m.disabled)
      return false

    var wanted = line.settings
    if (wanted.modeLiteral !== ("\"" + root.formatMode(m) + "\""))
      return false
    if (Math.abs(m.scale - parseFloat(wanted.scaleLiteral)) > 0.005)
      return false
    if ((m.transform || 0) !== wanted.transform)
      return false

    var liveMirror = String(m.mirrorOf || "none")
    var mirrored = liveMirror !== "none" && liveMirror.length > 0
    if (line.mirrorSource.length > 0)
      return mirrored
    if (mirrored)
      return false
    return line.position >= 0 && m.x === line.position && m.y === 0
  }

  // Re-sending a rule for an output that is already correct makes Hyprland
  // destroy and re-create its wl_output, and clients such as Firefox die with
  // it. Only outputs whose state really differs are touched.
  //
  // Every enable runs before every disable. Hyprland applies the rules in the
  // order they arrive, and a moment with zero outputs makes Qt fall back to a
  // placeholder screen, which segfaults the GTK backend and kills the shell.
  function apply() {
    root.seedFromLive()
    var lines = root.buildLines()
    if (lines.length === 0)
      return

    var enabled = []
    var changedEnabled = []
    var changedDisabled = []
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].enabled)
        enabled.push(lines[i].code)
      if (root.matchesLive(lines[i]))
        continue
      if (lines[i].enabled)
        changedEnabled.push(lines[i].code)
      else
        changedDisabled.push(lines[i].code)
    }
    if (enabled.length === 0)
      return

    file.setText(root.buildFile(enabled))

    var pending = changedEnabled.concat(changedDisabled).join(" ")
    if (pending.length === 0) {
      root.applied = ""
      return
    }
    // The same pending set twice over means Hyprland did not accept it; trying
    // again on every monitor event would loop forever.
    if (pending === root.applied)
      return
    root.applied = pending
    root.evalLines(pending)
  }

  // A rule set that only half applied leaves the machine with a dark screen and
  // no way back, so the shell puts an output on again itself.
  function rescueIfDark() {
    if (Monitors.activeCount > 0)
      return
    var names = root.resolveFallbackNames(root.resolveOrder())
    if (names.length === 0)
      return
    root.applied = ""
    root.evalLines("hl.monitor({ output = \"" + names[0]
      + "\", mode = \"preferred\", position = \"auto\", scale = \"auto\", disabled = false })")
  }

  function setEnabled(name, enabled) {
    var next = root.turnedOff.slice()
    var at = next.indexOf(name)
    if (enabled) {
      if (at < 0)
        return
      next.splice(at, 1)
    } else {
      if (at >= 0)
        return
      if (root.resolveEnabledNames().length <= 1)
        return
      next.push(name)
    }
    root.turnedOff = next
    root.apply()
  }

  function setIntent(names, mirrorOn) {
    root.turnedOff = names.slice()
    root.mirror = !!mirrorOn
    root.apply()
  }

  function setScale(name, scale) {
    var m = root.findMonitor(name)
    if (!m)
      return
    root.storeSetting(name, "scale", Monitors.snapScale(m.width, m.height, scale))
    root.apply()
  }

  function setMode(name, mode) {
    root.storeSetting(name, "mode", mode)
    root.apply()
  }

  function setTransform(name, transform) {
    root.storeSetting(name, "transform", transform)
    root.apply()
  }

  function restore() {
    root.turnedOff = StateStore.get("display.turnedOff", [])
    root.mirror = StateStore.get("display.mirror", false)
    root.outputs = StateStore.get("display.outputs", ({}))
    root.order = StateStore.get("display.order", [])
    root.apply()
  }

  onTurnedOffChanged: StateStore.set("display.turnedOff", root.turnedOff)
  onMirrorChanged: StateStore.set("display.mirror", root.mirror)
  onOutputsChanged: StateStore.set("display.outputs", root.outputs)
  onOrderChanged: StateStore.set("display.order", root.order)

  property Timer settleTimer: Timer {
    interval: 300
    onTriggered: {
      Monitors.refresh()
      root.rescueTimer.restart()
    }
  }

  property Timer rescueTimer: Timer {
    interval: 700
    onTriggered: root.rescueIfDark()
  }

  // A plug or an unplug changes what the intent resolves to, so the layout is
  // rebuilt from the outputs that are present now.
  property Timer reconcileTimer: Timer {
    interval: 200
    onTriggered: root.apply()
  }

  property Process applyProc: Process {
    onExited: Monitors.refresh()
  }

  property Connections monitorsConn: Connections {
    target: Monitors
    function onListChanged() {
      root.reconcileTimer.restart()
    }
  }

  property Connections stateConn: Connections {
    target: StateStore
    function onRestored() {
      root.restore()
    }
  }

  property FileView file: FileView {
    path: root.path
    printErrors: false
  }

  Component.onCompleted: {
    if (StateStore.ready)
      root.restore()
  }
}
