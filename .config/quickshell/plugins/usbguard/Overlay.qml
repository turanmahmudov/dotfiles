import QtQuick
import Quickshell

Item {
  id: root

  Component.onCompleted: Usbg.refresh()

  Connections {
    target: Usbg
    function onDeviceBlocked(name, id) {
      Quickshell.execDetached(["notify-send", "-a", "USB", "-u", "critical",
                               "USB device blocked", name])
    }
  }
}
