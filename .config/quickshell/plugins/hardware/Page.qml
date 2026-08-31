import QtQuick
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "System stats"

  property bool processesOpen: false

  function formatGb(v) {
    return (Math.round(v * 10) / 10).toFixed(1)
  }

  function formatVram(mb) {
    return (mb / 1024).toFixed(1)
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
    value: SystemStats.mem + "%  ·  " + panel.formatGb(SystemStats.memUsedGb) + " / " + panel.formatGb(SystemStats.memTotalGb) + " GB"
  }

  StatRow {
    iconName: "thermometer"
    label: "Temperature"
    value: SystemStats.temp + "°C"
    valueColor: SystemStats.temp >= 80 ? Theme.urgent : Theme.fg
  }

  SectionHeader {
    text: "Network" + (SystemStats.netIface.length > 0 ? "  ·  " + SystemStats.netIface : "")
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

  SectionHeader {
    visible: Nvidia.present
    text: "GPU" + (Nvidia.awake ? "  ·  " + Nvidia.name : "")
  }

  Text {
    width: parent.width
    visible: Nvidia.present && !Nvidia.awake
    text: "The card is asleep"
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize - 1
  }

  StatRow {
    visible: Nvidia.awake
    iconName: "gpu"
    label: "Load"
    value: Nvidia.util + "%"
  }

  StatRow {
    visible: Nvidia.awake
    iconName: "memory-stick"
    label: "Video memory"
    value: Nvidia.memPercent + "%  ·  " + panel.formatVram(Nvidia.memUsedMb) + " / " + panel.formatVram(Nvidia.memTotalMb) + " GB"
  }

  StatRow {
    visible: Nvidia.awake
    iconName: "thermometer"
    label: "Temperature"
    value: Nvidia.temp + "°C"
    valueColor: Nvidia.temp >= 85 ? Theme.urgent : Theme.fg
  }

  StatRow {
    visible: Nvidia.awake && Nvidia.powerDraw >= 0
    iconName: "zap"
    label: "Power"
    value: Nvidia.powerDraw.toFixed(1) + (Nvidia.powerLimit >= 0 ? " / " + Math.round(Nvidia.powerLimit) : "") + " W"
  }

  StatRow {
    visible: Nvidia.awake && Nvidia.fan >= 0
    iconName: "fan"
    label: "Fan"
    value: Math.round(Nvidia.fan) + "%"
  }

  StatRow {
    visible: Nvidia.awake
    iconName: "activity"
    label: "Clocks"
    value: Nvidia.clockSm + " / " + Nvidia.clockSmMax + " MHz  ·  " + Nvidia.clockMem + " MHz"
  }

  StatRow {
    visible: Nvidia.awake && (Nvidia.encUtil > 0 || Nvidia.decUtil > 0)
    iconName: "video"
    label: "Encode / decode"
    value: Nvidia.encUtil + "% / " + Nvidia.decUtil + "%"
  }

  StatRow {
    visible: Nvidia.awake
    iconName: "cable"
    label: "Link"
    value: "PCIe " + Nvidia.linkGen + " x" + Nvidia.linkWidth + "  ·  " + Nvidia.pstate
  }

  Rectangle {
    width: parent.width
    height: 30
    radius: Style.radiusSmall
    visible: Nvidia.awake
    color: processesArea.containsMouse ? Theme.alpha(Theme.fg, 0.12) : Theme.alpha(Theme.fg, 0.06)

    Row {
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      spacing: 6

      Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: panel.processesOpen ? "arrow-down" : "chevron-right"
        color: Theme.fgDim
        size: 14
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "GPU processes"
        color: Theme.fg
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize - 1
      }
    }

    Text {
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: Nvidia.processes.length
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 1
    }

    MouseArea {
      id: processesArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: panel.processesOpen = !panel.processesOpen
    }
  }

  Text {
    width: parent.width
    visible: Nvidia.awake && panel.processesOpen && Nvidia.processes.length === 0
    text: "Nothing is using the card"
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize - 1
  }

  Column {
    width: parent.width
    visible: Nvidia.awake && panel.processesOpen
    spacing: 2

    Repeater {
      model: Nvidia.processes

      StatRow {
        required property var modelData
        label: modelData.name + "  (" + modelData.kind + ")"
        value: modelData.memMb + " MB"
      }
    }
  }

  Timer {
    interval: 3000
    running: Nvidia.present
    repeat: true
    triggeredOnStart: true
    onTriggered: Nvidia.refreshProcesses()
  }
}
