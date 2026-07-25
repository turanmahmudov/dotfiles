pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Thin front end for ~/.local/bin/system-theme. The current selection is read
// from the generator's own state file, so switching from anywhere is reflected.
QtObject {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string themesDir: home + "/.config/themes"

  property string family: ""
  property string mode: ""
  property var variants: []

  readonly property var families: {
    var order = []
    var byFamily = ({})
    for (var i = 0; i < variants.length; i++) {
      var v = variants[i]
      if (!byFamily[v.family]) {
        byFamily[v.family] = { "family": v.family, "displayName": v.displayName, "modes": [], "variants": ({}) }
        order.push(v.family)
      }
      var entry = byFamily[v.family]
      entry.modes.push(v.mode)
      entry.variants[v.mode] = v
      if (v.mode === root.mode || entry.modes.length === 1)
        entry.displayName = v.displayName
    }
    var out = []
    for (var j = 0; j < order.length; j++)
      out.push(byFamily[order[j]])
    return out
  }

  readonly property string displayName: {
    for (var i = 0; i < variants.length; i++)
      if (variants[i].family === root.family && variants[i].mode === root.mode)
        return variants[i].displayName
    return root.family
  }

  function findWallpaper(family, mode) {
    for (var i = 0; i < variants.length; i++)
      if (variants[i].family === family && variants[i].mode === mode)
        return variants[i].wallpaper
    return ""
  }

  // Falls back to whichever variant exists so a family with only one mode still
  // shows a preview.
  function findPreview(entry, preferredMode) {
    if (!entry)
      return ""
    var v = entry.variants[preferredMode]
    if (v)
      return v.wallpaper
    for (var i = 0; i < entry.modes.length; i++) {
      var alt = entry.variants[entry.modes[i]]
      if (alt)
        return alt.wallpaper
    }
    return ""
  }

  function hasMode(family, mode) {
    for (var i = 0; i < variants.length; i++)
      if (variants[i].family === family && variants[i].mode === mode)
        return true
    return false
  }

  function apply(nextFamily, nextMode) {
    Quickshell.execDetached([root.home + "/.local/bin/system-theme", "set", nextFamily, nextMode || root.mode || "dark"])
  }

  function setMode(nextMode) {
    if (nextMode === root.mode)
      return
    Quickshell.execDetached([root.home + "/.local/bin/system-theme", "set-mode", nextMode])
  }

  function toggleMode() {
    root.setMode(root.mode === "light" ? "dark" : "light")
  }

  function refresh() {
    listProc.running = true
  }

  function parseState(raw) {
    var parts = String(raw || "").trim().split("/")
    root.family = parts[0] || ""
    root.mode = parts[1] || ""
  }

  function parseVariants(raw) {
    var lines = String(raw || "").split("\n")
    var out = []
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i])
        continue
      var f = lines[i].split("\t")
      if (f.length < 4 || !f[0] || !f[1])
        continue
      out.push({
        "family": f[0],
        "mode": f[1],
        "displayName": f[2] || f[0],
        "wallpaper": f[3] || ""
      })
    }
    root.variants = out
  }

  property IpcHandler ipc: IpcHandler {
    target: "theme"
    function get(): string {
      return root.family + "/" + root.mode
    }
    function set(family: string, mode: string): string {
      root.apply(family, mode)
      return "ok"
    }
    function setMode(mode: string): string {
      root.setMode(mode)
      return "ok"
    }
    function toggleMode(): string {
      root.toggleMode()
      return "ok"
    }
  }

  property Process listProc: Process {
    command: ["sh", "-c",
      'base="$1"; for d in "$base"/themes/*/*/; do ' +
      '  [ -f "${d}meta.yaml" ] || continue; ' +
      '  mode=$(basename "$d"); family=$(basename "$(dirname "$d")"); ' +
      '  wp=$(sed -n "s/^wallpaper:[[:space:]]*//p" "${d}meta.yaml" | head -1 | tr -d \'"\'); ' +
      '  name=$(sed -n "s/^display_name:[[:space:]]*//p" "${d}meta.yaml" | head -1 | tr -d \'"\'); ' +
      '  printf "%s\\t%s\\t%s\\t%s\\n" "$family" "$mode" "$name" "${d}${wp}"; ' +
      'done | sort',
      "sh", root.themesDir]
    stdout: StdioCollector {
      onStreamFinished: root.parseVariants(text)
    }
  }

  property FileView stateFile: FileView {
    path: root.themesDir + "/_generated/state"
    watchChanges: true
    printErrors: false
    onLoaded: root.parseState(text())
    onFileChanged: reload()
  }

  Component.onCompleted: root.refresh()
}
