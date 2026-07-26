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
    enabled: Screenshot.active && Screenshot.mode === "window"
    function onFocusedWorkspaceChanged() { Hyprland.refreshToplevels() }
  }

  Variants {
    model: Screenshot.active ? Quickshell.screens : []

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

      function captureMonitor() {
        Screenshot.confirm(0, 0, win.width, win.height, modelData.name)
      }

      screen: modelData
      color: "transparent"
      WlrLayershell.namespace: "quickshell-screenshot"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
      exclusionMode: ExclusionMode.Ignore
      exclusiveZone: 0
      anchors { top: true; bottom: true; left: true; right: true }

      ScreencopyView {
        id: freeze
        anchors.fill: parent
        captureSource: win.screen
        visible: Screenshot.mode === "region" && !Screenshot.capturing
        z: -1
      }

      RegionSelector {
        anchors.fill: parent
        visible: Screenshot.mode === "region" && freeze.hasContent && !Screenshot.capturing
        z: 1
        onRegionSelected: (x, y, w, h) => Screenshot.confirm(x, y, w, h, win.modelData.name)
        onCancelled: Screenshot.cancel()
      }

      WindowSelector {
        anchors.fill: parent
        visible: Screenshot.mode === "window" && !Screenshot.capturing
        z: 1
        monitor: win.hyprMonitor
        onWindowSelected: (x, y, w, h) => Screenshot.confirm(x, y, w, h, win.modelData.name)
      }

      MonitorSelector {
        anchors.fill: parent
        visible: Screenshot.mode === "monitor" && !Screenshot.capturing
        z: 1
        label: win.modelData.name + "  " + Math.round(win.width) + "×" + Math.round(win.height)
        onMonitorSelected: win.captureMonitor()
      }

      ControlBar {
        visible: win.focused && !Screenshot.capturing
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 60
        z: 5
      }

      Item {
        anchors.fill: parent
        focus: win.focused
        Keys.onEscapePressed: Screenshot.cancel()
        Keys.onPressed: (e) => {
          if (e.key === Qt.Key_R)
            Screenshot.setMode("region")
          else if (e.key === Qt.Key_W)
            Screenshot.setMode("window")
          else if (e.key === Qt.Key_S)
            Screenshot.setMode("monitor")
        }
        Component.onCompleted: if (win.focused) forceActiveFocus()
      }
    }
  }

  Variants {
    model: (Screenshot.capturing && Screenshot.countdown > 0) ? Quickshell.screens : []

    PanelWindow {
      required property var modelData
      readonly property bool focused:
        Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === modelData.name

      visible: focused
      screen: modelData
      color: "transparent"
      WlrLayershell.namespace: "quickshell-screenshot-countdown"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      exclusiveZone: 0
      anchors { bottom: true }
      margins.bottom: 120
      implicitWidth: 96
      implicitHeight: 96

      Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.alpha(Theme.bg, Style.surfaceAlpha)
        border.color: Theme.alpha(Theme.fg, 0.15)
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: Screenshot.countdown
          color: Theme.accent
          font.family: Style.fontFamily
          font.pixelSize: 40
          font.bold: true
        }
      }
    }
  }
}
