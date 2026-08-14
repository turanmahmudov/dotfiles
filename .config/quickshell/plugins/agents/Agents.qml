pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// State of the coding agents. Each agent reports itself through ~/.local/bin/agent,
// which owns the file. This side only reads it.
QtObject {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string statePath: {
    var runtime = Quickshell.env("XDG_RUNTIME_DIR")
    return ((runtime && runtime.length > 0) ? runtime : "/tmp") + "/agents.tsv"
  }

  property var list: []
  property int blocked: 0

  // A report older than this, from an agent that says it is working, means the agent stopped
  // reporting rather than that it is still busy: any turn ends with a report of its own.
  readonly property int silentAfter: 900
  property int now: 0

  function age(since) {
    return Math.max(0, root.now - parseInt(since, 10))
  }

  function ago(since) {
    var seconds = root.age(since)
    if (seconds < 60)
      return seconds + "s"
    if (seconds < 3600)
      return Math.floor(seconds / 60) + "m"
    return Math.floor(seconds / 3600) + "h"
  }

  function isSilent(entry) {
    return entry.state === "working" && root.age(entry.since) > root.silentAfter
  }

  readonly property bool waiting: blocked > 0
  readonly property string summary: {
    if (list.length === 0)
      return "No agents"
    if (blocked === 0)
      return list.length + (list.length === 1 ? " agent" : " agents")
    return blocked + " of " + list.length + " waiting for you"
  }

  function load(raw) {
    var agents = []
    var waits = 0
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var field = lines[i].split("\t")
      if (field.length < 9)
        continue
      agents.push({
        "key": field[0],
        "agent": field[1],
        "state": field[2],
        "pid": field[3],
        "pane": field[4],
        "title": field[5],
        "window": field[6],
        "place": field[7],
        "since": field[8]
      })
      if (field[2] === "blocked")
        waits++
    }
    root.blocked = waits
    root.list = agents
  }

  function focus(key) {
    Quickshell.execDetached([root.home + "/.local/bin/agent", "focus", key])
  }

  // An agent that is killed cannot report its own end, and the last one to die leaves
  // nobody behind to clean up after it. This drops those rows, and only rewrites the
  // file when something actually went away.
  property Process prune: Process {
    command: [root.home + "/.local/bin/agent", "list"]
  }

  property Timer pruneTimer: Timer {
    interval: 10000
    repeat: true
    running: root.list.length > 0
    onTriggered: root.prune.running = true
  }

  // The ages in the panel move on their own, so the clock has to tick even when the file does not.
  property Timer clock: Timer {
    interval: 15000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.now = Math.floor(Date.now() / 1000)
  }

  property FileView file: FileView {
    path: root.statePath
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.load(text())
    onLoadFailed: root.load("")
  }
}
