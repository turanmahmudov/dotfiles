pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

QtObject {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string path: home + "/.config/quickshell/shell.json"

  property var config: root.defaults()
  property bool loadedOnce: false

  // The editor writes this file, so it has to know whether the copy on disk is
  // still the one it last read. A hand edit that does not parse must survive
  // rather than be overwritten from memory.
  property bool fileParses: true
  property string lastGoodText: ""
  property bool backedUp: false

  // Normalized so an unexpected value cannot anchor the bar and its popups on
  // opposite edges.
  readonly property string barPosition: {
    var p = (config && config.bar && config.bar.position) ? String(config.bar.position).toLowerCase() : "top"
    return p === "bottom" ? "bottom" : "top"
  }
  readonly property var style: (config && config.style) ? config.style : ({})

  onStyleChanged: Style.applyConfig(style)

  readonly property var leftWidgets: (config && config.bar && config.bar.layout && config.bar.layout.left) ? config.bar.layout.left : []
  readonly property var centerWidgets: (config && config.bar && config.bar.layout && config.bar.layout.center) ? config.bar.layout.center : []
  readonly property var rightWidgets: (config && config.bar && config.bar.layout && config.bar.layout.right) ? config.bar.layout.right : []

  readonly property var ccSections: (config && config.cc && config.cc.layout) ? config.cc.layout : []
  readonly property var pluginSettings: (config && config.plugins) ? config.plugins : ({})

  // A plugin id holds dots, so these never go through the dotted path helpers.
  function readPluginSettings(pluginId) {
    var block = root.pluginSettings[pluginId]
    return (block && typeof block === "object") ? block : ({})
  }

  // What a widget sees. A key the plugin declares always comes from the plugin
  // block, never from the layout entry: an old entry key would otherwise mask the
  // value just set and look like the setting does nothing. The entry still carries
  // whatever no schema declares, such as the workspaces `persistent` map.
  function resolveSettings(pluginId, entry) {
    var declared = ({})
    var plugin = PluginRegistry.findPlugin(pluginId)
    var fields = plugin ? (plugin.settings || []) : []
    for (var i = 0; i < fields.length; i++)
      declared[fields[i].key] = true

    var out = ({})
    for (var own in entry)
      if (!declared[own])
        out[own] = entry[own]

    var values = root.readPluginSettings(pluginId)
    for (var key in values)
      out[key] = values[key]
    return out
  }

  function writePluginSetting(pluginId, key, value) {
    var next = JSON.parse(JSON.stringify(root.config || root.defaults()))
    if (!next.plugins || typeof next.plugins !== "object")
      next.plugins = ({})
    if (!next.plugins[pluginId] || typeof next.plugins[pluginId] !== "object")
      next.plugins[pluginId] = ({})
    next.plugins[pluginId][key] = value
    root.config = next
    writeTimer.restart()
  }

  function clearPluginSettings(pluginId) {
    var next = JSON.parse(JSON.stringify(root.config || root.defaults()))
    if (next.plugins)
      delete next.plugins[pluginId]
    root.config = next
    writeTimer.restart()
  }

  // Dropping the blocks is what restores the defaults: every value falls back to
  // the one its schema or Style declares. The layout is untouched.
  function clearAllSettings() {
    var next = JSON.parse(JSON.stringify(root.config || root.defaults()))
    delete next.style
    delete next.plugins
    if (next.bar)
      delete next.bar.position
    root.config = next
    writeTimer.restart()
  }

  function restoreDefaultLayout() {
    if (!root.defaultLayout || !root.defaultLayout.bar || !root.defaultLayout.cc) {
      console.warn("ConfigStore: no default layout to restore")
      return
    }
    var next = JSON.parse(JSON.stringify(root.config || root.defaults()))
    if (!next.bar || typeof next.bar !== "object")
      next.bar = ({})
    next.bar.layout = JSON.parse(JSON.stringify(root.defaultLayout.bar))
    next.cc = { "layout": JSON.parse(JSON.stringify(root.defaultLayout.cc)) }
    root.config = next
    root.flushConfig()
  }

  onBarPositionChanged: Style.barPosition = barPosition

  function defaults() {
    return {
      "version": 1,
      "bar": {
        "position": "top",
        "layout": { "left": [], "center": [], "right": [] }
      },
      "cc": {
        "layout": []
      }
    }
  }

  // The layout editor is the one writer of shell.json. It rewrites the whole file,
  // so the hand-authored keys have to survive the round trip. Both surfaces go in
  // one write, which keeps a bar change and a panel change from racing.
  function saveLayouts(barLayout, sections) {
    if (!root.fileParses) {
      console.warn("ConfigStore: shell.json does not parse, refusing to overwrite it")
      return
    }
    root.backupOnce()
    var next = JSON.parse(JSON.stringify(root.config || root.defaults()))
    if (!next.bar || typeof next.bar !== "object")
      next.bar = ({})
    next.bar.layout = {
      "left": barLayout.left || [],
      "center": barLayout.center || [],
      "right": barLayout.right || []
    }
    if (!next.cc || typeof next.cc !== "object")
      next.cc = ({})
    next.cc.layout = sections
    // Keep memory and file in step, so a read of the layout right after a save
    // cannot answer with the version this call replaced.
    root.config = next
    root.file.setText(JSON.stringify(next, null, 2) + "\n")
  }

  function loadFrom(raw) {
    try {
      var c = JSON.parse(raw)
      if (c && c.version === 1) {
        root.loadedOnce = true
        root.fileParses = true
        root.lastGoodText = raw
        config = c
        Style.barPosition = root.barPosition
        Style.applyConfig(root.style)
        return
      }
      console.warn("ConfigStore: unsupported config version, keeping previous config")
    } catch (e) {
      console.warn("ConfigStore: failed to parse shell.json:", e)
    }
    root.fileParses = false
  }

  // Single values by dotted key, for the forms that edit the shell's own options
  // rather than a layout. The value reaches memory at once so the change is live,
  // and the file write waits for the edit to settle.
  function readPath(path, fallback) {
    var parts = String(path).split(".")
    var node = root.config
    for (var i = 0; i < parts.length; i++) {
      if (!node || typeof node !== "object" || node[parts[i]] === undefined)
        return fallback
      node = node[parts[i]]
    }
    return node
  }

  function writePath(path, value) {
    var next = JSON.parse(JSON.stringify(root.config || root.defaults()))
    var parts = String(path).split(".")
    var node = next
    for (var i = 0; i < parts.length - 1; i++) {
      if (!node[parts[i]] || typeof node[parts[i]] !== "object")
        node[parts[i]] = ({})
      node = node[parts[i]]
    }
    node[parts[parts.length - 1]] = value
    root.config = next
    writeTimer.restart()
  }

  function flushConfig() {
    if (!root.fileParses) {
      console.warn("ConfigStore: shell.json does not parse, refusing to overwrite it")
      return
    }
    root.backupOnce()
    root.file.setText(JSON.stringify(root.config, null, 2) + "\n")
  }

  property Timer writeTimer: Timer {
    interval: 400
    onTriggered: root.flushConfig()
  }

  // One copy per session, taken from the text that last parsed, so an edit made
  // through the shell always has something to fall back to.
  function backupOnce() {
    if (root.backedUp || root.lastGoodText.length === 0)
      return
    root.backedUp = true
    root.backupFile.setText(root.lastGoodText)
  }

  function applyDefaultsInMemory() {
    config = defaults()
    Style.barPosition = root.barPosition
  }

  property FileView backupFile: FileView {
    path: root.path + ".bak"
    printErrors: false
  }

  // The layout the shell ships with, for the restore action. Read only.
  property var defaultLayout: null

  property FileView defaultsFile: FileView {
    path: root.home + "/.config/quickshell/defaults/layout.json"
    printErrors: false
    onLoaded: {
      try {
        root.defaultLayout = JSON.parse(text())
      } catch (e) {
        console.warn("ConfigStore: failed to parse the default layout:", e)
      }
    }
  }

  property FileView file: FileView {
    path: root.path
    watchChanges: true
    printErrors: false
    onLoaded: root.loadFrom(text())
    onFileChanged: reload()
    // Missing file only: seed defaults once. A failure after a good load is
    // transient, and taking the defaults there would hand an empty layout to the
    // editor, which then saves that emptiness over the real file.
    onLoadFailed: (error) => {
      console.warn("ConfigStore: load failed", error)
      if (!root.loadedOnce)
        root.applyDefaultsInMemory()
    }
  }

  Component.onCompleted: Style.barPosition = root.barPosition
}
