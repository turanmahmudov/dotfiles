import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  readonly property string metric: (settings && settings.metric) ? String(settings.metric) : "mem"
  readonly property int metricValue: {
    if (root.metric === "cpu")
      return SystemStats.cpu
    if (root.metric === "temp")
      return SystemStats.temp
    return SystemStats.mem
  }
  readonly property string metricIcon: {
    if (root.metric === "cpu")
      return "cpu"
    if (root.metric === "temp")
      return "thermometer"
    return "memory-stick"
  }

  tooltipText: "CPU " + SystemStats.cpu + "%  ·  Mem " + SystemStats.mem + "%  ·  " + SystemStats.temp + "°C"
  onClicked: openPanel()

  Row {
    spacing: 4

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      name: root.metricIcon
      color: root.hovered ? Theme.fgDim : Theme.fg
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.metricValue + (root.metric === "temp" ? "°C" : "%")
      color: root.hovered ? Theme.fgDim : Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
    }
  }
}
