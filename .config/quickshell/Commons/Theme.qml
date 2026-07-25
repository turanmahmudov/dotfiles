pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property color bg: "#1e1e2e"
  property color bgAlt: "#181825"
  property color bgAlt2: "#313244"
  property color surface: "#45475a"
  property color fg: "#cdd6f4"
  property color fgDim: "#a6adc8"
  property color fgBright: "#f5e0dc"
  property color accent: "#89b4fa"
  property color accentAlt: "#b4befe"
  property color accentActive: "#a6e3a1"
  property color urgent: "#fab387"
  property color success: "#a6e3a1"
  property color warning: "#f9e2af"
  property color error: "#f38ba8"
  property color info: "#94e2d5"

  function alpha(c, a) {
    return Qt.rgba(c.r, c.g, c.b, a)
  }

  function applyPalette(raw) {
    try {
      var p = JSON.parse(raw)
      if (p.bg) bg = p.bg
      if (p.bg_alt) bgAlt = p.bg_alt
      if (p.bg_alt2) bgAlt2 = p.bg_alt2
      if (p.surface) surface = p.surface
      if (p.fg) fg = p.fg
      if (p.fg_dim) fgDim = p.fg_dim
      if (p.fg_bright) fgBright = p.fg_bright
      if (p.accent) accent = p.accent
      if (p.accent_alt) accentAlt = p.accent_alt
      if (p.active) accentActive = p.active
      if (p.urgent) urgent = p.urgent
      if (p.success) success = p.success
      if (p.warning) warning = p.warning
      if (p.error) error = p.error
      if (p.info) info = p.info
    } catch (e) {
      console.warn("Theme: failed to parse palette json:", e)
    }
  }

  property FileView paletteFile: FileView {
    path: Quickshell.env("HOME") + "/.config/themes/_generated/quickshell.json"
    watchChanges: true
    printErrors: false
    onLoaded: root.applyPalette(text())
    onFileChanged: reload()
  }
}
