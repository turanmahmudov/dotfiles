import QtQuick
import Quickshell
import qs.Commons
import qs.Services
import qs.Ui

BarItem {
  id: root

  tooltipText: "Keyboard layout: " + (Hypr.kbLayoutFull || Hypr.kbLayout)
  onClicked: {
    Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
    layoutTimer.restart()
  }

  Timer {
    id: layoutTimer
    interval: 200
    onTriggered: Hypr.refreshDevices()
  }

  Row {
    spacing: 5

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      name: "keyboard"
      color: root.hovered ? Theme.fgDim : Theme.fg
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Hypr.kbLayout
      color: root.hovered ? Theme.fgDim : Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
    }
  }
}
