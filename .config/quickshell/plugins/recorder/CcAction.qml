import QtQuick
import qs.Ui

Tile {
  id: root

  property var settings: ({})
  property var controller: null

  readonly property string mode: (settings && settings.mode) ? String(settings.mode) : "region"

  iconName: "video"
  label: Recorder.recording ? "Recording" : "Record"
  sublabel: {
    if (Recorder.recording)
      return Recorder.elapsedLabel
    if (root.mode === "monitor")
      return "Whole screen"
    if (root.mode === "window")
      return "Pick a window"
    return "Select a region"
  }
  active: Recorder.recording
  onTriggered: {
    if (root.controller)
      root.controller.close()
    if (Recorder.recording)
      Recorder.stop()
    else
      Recorder.open(root.mode)
  }
}
