pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Each SVG is read from disk once and each name/color pair is encoded once,
// rather than per Icon instance.
QtObject {
  id: root

  readonly property string iconDir: Quickshell.env("HOME") + "/.config/quickshell/icons/"

  property int revision: 0
  property var svgByName: ({})
  property var uriByKey: ({})
  property var pendingByName: ({})

  function toHex(c) {
    function component(x) {
      var s = Math.round(x * 255).toString(16)
      return s.length < 2 ? "0" + s : s
    }
    return "#" + component(c.r) + component(c.g) + component(c.b)
  }

  function request(name) {
    if (!name || !name.length)
      return
    if (svgByName[name] !== undefined || pendingByName[name])
      return
    pendingByName[name] = loaderComponent.createObject(root, { "iconName": name })
  }

  function store(name, svg) {
    var next = svgByName
    next[name] = svg
    svgByName = next
    var pending = pendingByName[name]
    if (pending) {
      delete pendingByName[name]
      pending.destroy()
    }
    revision = revision + 1
  }

  function source(name, color) {
    root.revision
    if (!name || !name.length)
      return ""
    var svg = svgByName[name]
    if (!svg)
      return ""
    var key = name + "|" + root.toHex(color)
    var cached = uriByKey[key]
    if (cached)
      return cached
    var uri = "data:image/svg+xml;utf8,"
      + svg.replace(/\n/g, " ").replace(/currentColor/g, root.toHex(color)).replace(/#/g, "%23")
    uriByKey[key] = uri
    return uri
  }

  property Component loaderComponent: Component {
    FileView {
      property string iconName: ""
      path: root.iconDir + iconName + ".svg"
      printErrors: false
      onLoaded: root.store(iconName, text())
      onLoadFailed: root.store(iconName, "")
    }
  }
}
