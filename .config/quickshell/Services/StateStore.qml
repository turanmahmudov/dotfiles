pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Runtime state the shell owns and rewrites, kept out of the hand-authored
// shell.json. Consumers restore on `restored` and persist via set().
QtObject {
  id: root

  readonly property string dir: {
    var stateHome = Quickshell.env("XDG_STATE_HOME")
    var base = (stateHome && stateHome.length > 0) ? stateHome : Quickshell.env("HOME") + "/.local/state"
    return base + "/quickshell"
  }
  readonly property string path: dir + "/state.json"

  property bool ready: false
  property var values: ({})

  signal restored()

  function get(key, fallback) {
    var v = values[key]
    return v === undefined ? fallback : v
  }

  function set(key, value) {
    if (!ready || values[key] === value)
      return
    var next = values
    next[key] = value
    values = next
    saveTimer.restart()
  }

  function load(raw) {
    try {
      var parsed = JSON.parse(raw)
      if (parsed && typeof parsed === "object" && !Array.isArray(parsed))
        values = parsed
    } catch (e) {
      console.warn("StateStore: failed to parse state.json:", e)
    }
    root.markReady()
  }

  function markReady() {
    if (root.ready)
      return
    root.ready = true
    root.restored()
  }

  property Timer saveTimer: Timer {
    interval: 400
    onTriggered: root.file.setText(JSON.stringify(root.values, null, 2) + "\n")
  }

  // Deliberately unwatched: the shell is the only writer, and reloading its own
  // writes would fight with in-memory state.
  property FileView file: FileView {
    path: root.path
    printErrors: false
    onLoaded: root.load(text())
    onLoadFailed: root.markReady()
  }
}
