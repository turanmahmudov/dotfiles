pragma Singleton
import QtQuick
import Quickshell
import qs.Services

QtObject {
  id: root

  function cycleNext() {
    Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
    refreshTimer.restart()
  }

  // Hyprland reports the new layout only after it applied the switch.
  property Timer refreshTimer: Timer {
    interval: 200
    onTriggered: Hypr.refreshDevices()
  }
}
