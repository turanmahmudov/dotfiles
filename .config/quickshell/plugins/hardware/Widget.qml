import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  readonly property string setting: (settings && settings.metric) ? String(settings.metric) : "mem"

  // A machine with no card falls back to memory, so a config carried over from
  // one that has a card still shows a reading.
  readonly property string metric: (root.setting.indexOf("gpu") === 0 && !Nvidia.present) ? "mem" : root.setting
  readonly property bool isGpu: root.metric.indexOf("gpu") === 0

  readonly property string metricText: {
    if (root.isGpu && !Nvidia.awake)
      return "zZ"
    if (root.metric === "gpu")
      return Nvidia.util + "%"
    if (root.metric === "gpuTemp")
      return Nvidia.temp + "°C"
    if (root.metric === "gpuMem")
      return Nvidia.memPercent + "%"
    if (root.metric === "gpuPower")
      return Nvidia.powerDraw >= 0 ? Math.round(Nvidia.powerDraw) + "W" : "-"
    if (root.metric === "cpu")
      return SystemStats.cpu + "%"
    if (root.metric === "temp")
      return SystemStats.temp + "°C"
    return SystemStats.mem + "%"
  }

  readonly property string metricIcon: {
    if (root.metric === "gpu" || root.metric === "gpuMem")
      return "gpu"
    if (root.metric === "gpuTemp")
      return "thermometer"
    if (root.metric === "gpuPower")
      return "zap"
    if (root.metric === "cpu")
      return "cpu"
    if (root.metric === "temp")
      return "thermometer"
    return "memory-stick"
  }

  readonly property bool hot: root.isGpu ? (Nvidia.awake && Nvidia.temp >= 85) : (SystemStats.temp >= 80)

  tooltipText: {
    var text = "CPU " + SystemStats.cpu + "%  ·  Mem " + SystemStats.mem + "%  ·  " + SystemStats.temp + "°C"
    if (Nvidia.awake)
      text += "\nGPU " + Nvidia.util + "%  ·  " + Nvidia.temp + "°C  ·  "
        + Nvidia.memUsedMb + " / " + Nvidia.memTotalMb + " MB"
    else if (Nvidia.present)
      text += "\nGPU asleep"
    return text
  }
  onClicked: openPanel()

  Row {
    spacing: Style.spaceTight

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      name: root.metricIcon
      color: root.hovered ? Theme.fgDim : Theme.fg
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.metricText
      color: root.hot ? Theme.urgent : (root.hovered ? Theme.fgDim : Theme.fg)
      font.family: Style.fontFamily
      font.pixelSize: Style.fontTitle
    }
  }
}
