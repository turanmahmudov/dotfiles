import QtQuick
import qs.Ui

Tile {
  id: root

  property var settings: ({})
  property var controller: null

  readonly property string mode: (settings && settings.mode) ? String(settings.mode) : "region"

  iconName: "crop"
  label: "Screenshot"
  sublabel: {
    if (root.mode === "monitor")
      return "Whole screen"
    if (root.mode === "window")
      return "Pick a window"
    return "Select a region"
  }
  onTriggered: {
    if (root.controller)
      root.controller.close()
    Screenshot.open(root.mode)
  }
}
