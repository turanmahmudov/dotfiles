pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  // Day key "YYYY-MM-DD" to the list of events on that day.
  property var eventsByDay: ({})
  property bool failed: false

  function load(firstDay, lastDay) {
    if (proc.running && proc.command[1] === firstDay && proc.command[2] === lastDay)
      return
    proc.running = false
    proc.command = [Quickshell.env("HOME") + "/.local/bin/calendar-events", firstDay, lastDay]
    proc.running = true
  }

  function parse(text, firstDay, lastDay) {
    if (text.trim().length === 0)
      return
    var list
    try {
      list = JSON.parse(text)
    } catch (e) {
      console.warn("clock: failed to parse calendar-events output:", e)
      return
    }
    var next = {}
    for (var cachedKey in root.eventsByDay) {
      if (cachedKey < firstDay || cachedKey > lastDay)
        next[cachedKey] = root.eventsByDay[cachedKey]
    }
    for (var i = 0; i < list.length; i++) {
      for (var j = 0; j < list[i].days.length; j++) {
        var key = list[i].days[j]
        if (!next[key])
          next[key] = []
        next[key].push(list[i])
      }
    }
    root.eventsByDay = next
  }

  property Process proc: Process {
    stdout: StdioCollector {
      onStreamFinished: root.parse(text, root.proc.command[1], root.proc.command[2])
    }
    onExited: (code, status) => {
      // QProcess::NormalExit; quickshell does not expose the enum to QML.
      if (status === 0)
        root.failed = code !== 0
    }
  }
}
