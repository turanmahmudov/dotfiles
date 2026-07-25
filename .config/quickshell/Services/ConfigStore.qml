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

  // Normalized so an unexpected value cannot anchor the bar and its popups on
  // opposite edges.
  readonly property string barPosition: {
    var p = (config && config.bar && config.bar.position) ? String(config.bar.position).toLowerCase() : "top"
    return p === "bottom" ? "bottom" : "top"
  }
  readonly property var leftWidgets: (config && config.bar && config.bar.layout && config.bar.layout.left) ? config.bar.layout.left : []
  readonly property var centerWidgets: (config && config.bar && config.bar.layout && config.bar.layout.center) ? config.bar.layout.center : []
  readonly property var rightWidgets: (config && config.bar && config.bar.layout && config.bar.layout.right) ? config.bar.layout.right : []

  onBarPositionChanged: Style.barPosition = barPosition

  function defaults() {
    return {
      "version": 1,
      "bar": {
        "position": "top",
        "layout": { "left": [], "center": [], "right": [] }
      }
    }
  }

  function loadFrom(raw) {
    try {
      var c = JSON.parse(raw)
      if (c && c.version === 1) {
        config = c
        Style.barPosition = root.barPosition
        return
      }
      console.warn("ConfigStore: unsupported config version, keeping previous config")
    } catch (e) {
      console.warn("ConfigStore: failed to parse shell.json:", e)
    }
  }

  function applyDefaultsInMemory() {
    config = defaults()
    Style.barPosition = root.barPosition
  }

  property FileView file: FileView {
    path: root.path
    watchChanges: true
    printErrors: false
    onLoaded: root.loadFrom(text())
    onFileChanged: reload()
    // Missing file only: seed defaults once. Never overwrite an existing file
    // on transient load failures (that wiped shell.json during restarts).
    onLoadFailed: (error) => {
      console.warn("ConfigStore: load failed", error)
      root.applyDefaultsInMemory()
    }
  }

  Component.onCompleted: Style.barPosition = root.barPosition
}
