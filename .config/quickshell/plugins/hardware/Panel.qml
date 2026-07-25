import QtQuick
import qs.Commons
import qs.Ui

Popup {
  id: panel
  pluginId: "shell.hardware"
  title: "System"
  cardWidth: 320

  function gb(v) {
    return (Math.round(v * 10) / 10).toFixed(1)
  }

  function formatSpeed(bps) {
    if (bps >= 1048576)
      return (bps / 1048576).toFixed(1) + " MB/s"
    if (bps >= 1024)
      return Math.round(bps / 1024) + " KB/s"
    return Math.round(bps) + " B/s"
  }

  component StatRow: Item {
    property string iconName: ""
    property string label: ""
    property string value: ""
    property color valueColor: Theme.fg
    width: parent.width
    height: 22

    Row {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      spacing: 8

      Icon {
        anchors.verticalCenter: parent.verticalCenter
        visible: iconName.length > 0
        name: iconName
        color: Theme.fgDim
        size: 16
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: label
        color: Theme.fgDim
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize - 1
      }
    }

    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: value
      color: valueColor
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 1
    }
  }

  StatRow {
    iconName: "cpu"
    label: "CPU"
    value: SystemStats.cpu + "%"
  }

  StatRow {
    iconName: "memory-stick"
    label: "Memory"
    value: SystemStats.mem + "%  ·  " + panel.gb(SystemStats.memUsedGb) + " / " + panel.gb(SystemStats.memTotalGb) + " GB"
  }

  StatRow {
    iconName: "thermometer"
    label: "Temperature"
    value: SystemStats.temp + "°C"
    valueColor: SystemStats.temp >= 80 ? Theme.urgent : Theme.fg
  }

  Text {
    text: "Network" + (SystemStats.netIface.length > 0 ? "  ·  " + SystemStats.netIface : "")
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize - 2
  }

  StatRow {
    iconName: "arrow-down"
    label: "Down"
    value: panel.formatSpeed(SystemStats.netDown)
  }

  StatRow {
    iconName: "arrow-up"
    label: "Up"
    value: panel.formatSpeed(SystemStats.netUp)
  }
}
