import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

Item {
  id: overlayRoot

  Connections {
    target: Hyprland
    enabled: Recorder.active && Recorder.mode === "window"
    function onFocusedWorkspaceChanged() { Hyprland.refreshToplevels() }
  }

  Variants {
    model: Recorder.active ? Quickshell.screens : []

    PanelWindow {
      id: win
      required property var modelData

      readonly property bool focused:
        Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === modelData.name

      readonly property var hyprMonitor: {
        var list = Hyprland.monitors.values
        for (var i = 0; i < list.length; i++)
          if (list[i].name === modelData.name)
            return list[i]
        return null
      }

      screen: modelData
      color: "transparent"
      WlrLayershell.namespace: "quickshell-recorder"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
      exclusionMode: ExclusionMode.Ignore
      exclusiveZone: 0
      anchors { top: true; bottom: true; left: true; right: true }

      // Unlike the screenshot overlay there is no frozen frame: what gets
      // recorded is whatever happens after the selection, not this instant.
      RegionSelector {
        anchors.fill: parent
        visible: Recorder.mode === "region"
        z: 1
        onRegionSelected: (x, y, w, h) => Recorder.confirm(x, y, w, h, win.modelData.name)
        onCancelled: Recorder.cancel()
      }

      WindowSelector {
        anchors.fill: parent
        visible: Recorder.mode === "window"
        z: 1
        monitor: win.hyprMonitor
        onWindowSelected: (x, y, w, h) => Recorder.confirm(x, y, w, h, win.modelData.name)
      }

      MonitorSelector {
        anchors.fill: parent
        visible: Recorder.mode === "monitor"
        z: 1
        label: win.modelData.name + "  " + Math.round(win.width) + "×" + Math.round(win.height)
        onMonitorSelected: Recorder.confirm(0, 0, win.width, win.height, win.modelData.name)
      }

      ControlBar {
        visible: win.focused
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 60
        z: 5
      }

      Item {
        anchors.fill: parent
        focus: win.focused
        Keys.onEscapePressed: Recorder.cancel()
        Keys.onPressed: (e) => {
          if (e.key === Qt.Key_R)
            Recorder.setMode("region")
          else if (e.key === Qt.Key_W)
            Recorder.setMode("window")
          else if (e.key === Qt.Key_S)
            Recorder.setMode("monitor")
          else if (e.key === Qt.Key_A)
            Recorder.toggleAudio()
        }
        Component.onCompleted: if (win.focused) forceActiveFocus()
      }
    }
  }
}
