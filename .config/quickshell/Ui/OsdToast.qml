import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services

PanelWindow {
  id: osd

  property string iconName: ""
  property real level: 0
  property bool ready: false

  screen: Hypr.focusedScreen
  color: "transparent"
  WlrLayershell.namespace: "quickshell-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  anchors.bottom: true
  margins.bottom: 90
  exclusiveZone: 0
  implicitWidth: 220
  implicitHeight: 56
  visible: false

  function show(icon, lvl) {
    if (!ready)
      return
    iconName = icon
    level = lvl
    visible = true
    hideTimer.restart()
  }

  Timer {
    id: hideTimer
    interval: 1300
    onTriggered: osd.visible = false
  }

  Timer {
    interval: 1500
    running: true
    onTriggered: osd.ready = true
  }

  Rectangle {
    anchors.fill: parent
    radius: Style.radius
    color: Theme.alpha(Theme.bg, Style.surfaceAlpha)
    border.color: Theme.alpha(Theme.fg, 0.15)
    border.width: 1

    Row {
      anchors.fill: parent
      anchors.margins: 14
      spacing: 12

      Icon {
        anchors.verticalCenter: parent.verticalCenter
        size: 22
        name: osd.iconName
        color: Theme.fg
      }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 34
        height: 6
        radius: 3
        color: Theme.alpha(Theme.fg, 0.15)

        Rectangle {
          width: parent.width * Math.max(0, Math.min(1, osd.level))
          height: parent.height
          radius: 3
          color: Theme.accent
        }
      }
    }
  }
}
