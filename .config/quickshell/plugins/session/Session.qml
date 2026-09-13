pragma Singleton
import QtQuick
import Quickshell

// The one pending session question. A tile hands the command over and closes the
// panel; the overlay asks, and only the overlay runs it.
QtObject {
  id: root

  property string iconName: ""
  property string label: ""
  property string message: ""
  property string command: ""
  property bool danger: false

  readonly property bool asking: root.command.length > 0

  function ask(iconName, label, message, command, danger) {
    root.iconName = iconName
    root.label = label
    root.message = message
    root.danger = danger
    root.command = command
  }

  function cancel() {
    root.command = ""
  }

  function confirm() {
    var command = root.command
    root.command = ""
    if (command.length > 0)
      Quickshell.execDetached(["sh", "-c", command])
  }
}
