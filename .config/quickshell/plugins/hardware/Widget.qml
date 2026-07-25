import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  tooltipText: "CPU " + SystemStats.cpu + "%  ·  Mem " + SystemStats.mem + "%  ·  " + SystemStats.temp + "°C"
  onClicked: openPanel()

  Row {
    spacing: 4

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      name: "memory-stick"
      color: root.hovered ? Theme.fgDim : Theme.fg
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: SystemStats.mem + "%"
      color: root.hovered ? Theme.fgDim : Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
    }
  }
}
