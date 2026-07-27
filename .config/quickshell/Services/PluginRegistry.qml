pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Plugins are discovered from their manifest.json. A plugin declares what it
// exposes; shell.json decides where those pieces go.
QtObject {
  id: root

  readonly property string configDir: Quickshell.env("HOME") + "/.config/quickshell"
  readonly property string pluginsDir: configDir + "/plugins"

  property var installed: ({})
  property int revision: 0

  readonly property var surfaces: ["bar", "cc"]
  readonly property string recordSeparator: String.fromCharCode(30)

  function findPlugin(id) {
    return installed[id] || null
  }

  // A reference is "shell.audio" or "shell.display:brightness".
  function parseRef(ref) {
    var text = String(ref || "")
    var colon = text.indexOf(":")
    if (colon < 0)
      return { "id": text, "widget": "" }
    return { "id": text.substring(0, colon), "widget": text.substring(colon + 1) }
  }

  // A bare reference resolves only while the plugin has one widget on that
  // surface. With more than one, the reference has to name the widget.
  function findWidget(ref, surface) {
    var parsed = parseRef(ref)
    var plugin = installed[parsed.id]
    if (!plugin)
      return null
    if (parsed.widget.length > 0) {
      var named = plugin.widgets[parsed.widget]
      return (named && named.surface === surface) ? named : null
    }
    var match = null
    for (var name in plugin.widgets) {
      var widget = plugin.widgets[name]
      if (widget.surface !== surface)
        continue
      if (match)
        return null
      match = widget
    }
    return match
  }

  function resolveWidgetUrl(ref, surface) {
    if (!ref || String(ref).length === 0)
      return ""
    var widget = findWidget(ref, surface)
    if (widget)
      return widget.url
    if (revision > 0)
      console.warn("PluginRegistry: no", surface, "widget for", ref)
    return ""
  }

  function findPage(id) {
    var plugin = installed[id]
    return (plugin && plugin.page) ? plugin.page : null
  }

  function resolvePageUrl(id) {
    var page = findPage(id)
    return page ? page.url : ""
  }

  // A "cc" page belongs to the Control Center hierarchy; a "standalone" page
  // opens under the widget that summoned it.
  function resolvePageMode(id) {
    var page = findPage(id)
    return page ? page.mode : ""
  }

  function listOverlayUrls() {
    var out = []
    for (var id in installed) {
      var overlay = installed[id].overlay
      if (overlay)
        out.push(overlay.url)
    }
    return out
  }

  function listPlugins() {
    var out = []
    for (var id in installed)
      out.push(installed[id])
    return out
  }

  function buildWidgets(dir, declared) {
    var out = ({})
    for (var name in declared) {
      var widget = declared[name] || ({})
      var surface = String(widget.surface || "")
      if (surfaces.indexOf(surface) === -1) {
        console.warn("PluginRegistry:", dir, "widget", name, "has unknown surface", surface)
        continue
      }
      if (!widget.file) {
        console.warn("PluginRegistry:", dir, "widget", name, "has no file")
        continue
      }
      out[name] = {
        "name": name,
        "surface": surface,
        "file": String(widget.file),
        "url": "file://" + dir + "/" + widget.file
      }
    }
    return out
  }

  function resolvePlacement(widgets) {
    var onBar = false
    var onCc = false
    for (var name in widgets) {
      if (widgets[name].surface === "cc")
        onCc = true
      else
        onBar = true
    }
    if (onBar && onCc)
      return "bar-and-cc"
    if (onCc)
      return "cc"
    if (onBar)
      return "bar"
    return "none"
  }

  function buildPage(dir, declared) {
    if (!declared || !declared.file)
      return null
    var mode = String(declared.mode || "cc")
    if (mode !== "cc" && mode !== "standalone") {
      console.warn("PluginRegistry:", dir, "page has unknown mode", mode)
      mode = "cc"
    }
    return {
      "mode": mode,
      "file": String(declared.file),
      "url": "file://" + dir + "/" + declared.file
    }
  }

  function buildOverlay(dir, declared) {
    if (!declared || !declared.file)
      return null
    return {
      "file": String(declared.file),
      "url": "file://" + dir + "/" + declared.file
    }
  }

  function buildPlugin(dir, json) {
    var base = dir.substring(dir.lastIndexOf("/") + 1)
    if (!base)
      return null
    var manifest
    try {
      manifest = JSON.parse(json)
    } catch (e) {
      console.warn("PluginRegistry: failed to parse the manifest of", base, e)
      return null
    }
    var widgets = buildWidgets(dir, manifest.widgets || ({}))
    return {
      "id": "shell." + base,
      "dirName": base,
      "name": String(manifest.name || base),
      // Settings belong to the plugin, not to one placement of it, and the shell
      // settings page is the one place that edits them.
      "settings": Array.isArray(manifest.settings) ? manifest.settings : [],
      "widgets": widgets,
      "placement": resolvePlacement(widgets),
      "page": buildPage(dir, manifest.page),
      "overlay": buildOverlay(dir, manifest.overlay),
      "__sourceDir": dir
    }
  }

  // One record per plugin: the directory on the first line, then the manifest.
  // A record separator keeps manifest text safe from the split.
  function parseScan(out) {
    var next = ({})
    var records = String(out || "").split(root.recordSeparator)
    for (var i = 0; i < records.length; i++) {
      var record = records[i]
      if (record.trim().length === 0)
        continue
      var newline = record.indexOf("\n")
      if (newline < 0)
        continue
      var plugin = buildPlugin(record.substring(0, newline).trim(), record.substring(newline + 1))
      if (plugin)
        next[plugin.id] = plugin
    }
    installed = next
    revision = revision + 1
  }

  function scan() {
    scanProc.running = true
  }

  property Process scanProc: Process {
    command: ["sh", "-c",
      'base="$1"; [ -d "$base" ] || exit 0; ' +
      'for d in "$base"/*/; do ' +
      '  [ -f "${d}manifest.json" ] || continue; ' +
      '  printf "\\036%s\\n" "${d%/}"; ' +
      '  cat "${d}manifest.json"; ' +
      '  printf "\\n"; ' +
      'done',
      "sh", root.pluginsDir]
    stdout: StdioCollector {
      onStreamFinished: root.parseScan(text)
    }
  }

  Component.onCompleted: scan()
}
