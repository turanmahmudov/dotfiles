pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  readonly property string pluginsDir: Quickshell.env("HOME") + "/.config/quickshell/plugins"

  property var installed: ({})
  property int revision: 0

  readonly property var kindFiles: ({
    "bar-widget": "Widget.qml",
    "panel": "Panel.qml",
    "overlay": "Overlay.qml"
  })

  function hasKind(id, kind) {
    var m = installed[id]
    return !!(m && Array.isArray(m.kinds) && m.kinds.indexOf(kind) !== -1)
  }

  function pluginsOfKind(kind) {
    var out = []
    for (var id in installed)
      if (hasKind(id, kind))
        out.push(id)
    return out
  }

  function entryPointUrl(id, kind) {
    var m = installed[id]
    if (!m || !m.__sourceDir)
      return ""
    var file = kindFiles[kind]
    if (!file || !m.kinds || m.kinds.indexOf(kind) === -1)
      return ""
    return "file://" + m.__sourceDir + "/" + file
  }

  function barWidgetUrl(id) {
    return entryPointUrl(id, "bar-widget")
  }

  function panelUrl(id) {
    return entryPointUrl(id, "panel")
  }

  function parseScan(out) {
    var next = ({})
    var lines = String(out || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (!line)
        continue
      var tab = line.indexOf("\t")
      if (tab < 0)
        continue
      var dir = line.substring(0, tab)
      var kindsCsv = line.substring(tab + 1)
      var base = dir.substring(dir.lastIndexOf("/") + 1)
      if (!base)
        continue
      var id = "shell." + base
      var kinds = kindsCsv ? kindsCsv.split(",") : []
      if (kinds.length === 0)
        continue
      next[id] = {
        "id": id,
        "name": base,
        "kinds": kinds,
        "__sourceDir": dir
      }
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
      '  [ -d "$d" ] || continue; ' +
      '  kinds=""; ' +
      '  [ -f "${d}Widget.qml" ] && kinds="${kinds}${kinds:+,}bar-widget"; ' +
      '  [ -f "${d}Panel.qml" ] && kinds="${kinds}${kinds:+,}panel"; ' +
      '  [ -f "${d}Overlay.qml" ] && kinds="${kinds}${kinds:+,}overlay"; ' +
      '  [ -n "$kinds" ] || continue; ' +
      '  printf "%s\\t%s\\n" "${d%/}" "$kinds"; ' +
      'done | sort',
      "sh", root.pluginsDir]
    stdout: StdioCollector {
      onStreamFinished: root.parseScan(text)
    }
  }

  Component.onCompleted: scan()
}
