import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "System stats"

  property var topProcesses: []

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

  function formatMib(mib) {
    if (mib >= 1024)
      return (mib / 1024).toFixed(1) + " GB"
    return Math.round(mib) + " MB"
  }

  function parseTopProcesses(text) {
    var list = []
    var lines = String(text).split("\n")
    for (var i = 0; i < lines.length; i++) {
      var f = lines[i].trim().split(/\s+/)
      if (f.length < 12)
        continue
      list.push({
        "name": f.slice(11).join(" "),
        "cpu": Math.round(parseFloat(f[8]) || 0),
        "memMib": parseFloat(f[5]) || 0
      })
    }
    panel.topProcesses = list
  }

  component StatRow: Item {
    property string iconName: ""
    property color iconColor: Theme.fgDim
    property string label: ""
    property string value: ""
    property color valueColor: Theme.fg
    width: parent.width
    height: 22

    Row {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space

      Icon {
        anchors.verticalCenter: parent.verticalCenter
        visible: iconName.length > 0
        name: iconName
        color: iconColor
        size: Style.iconSmall
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: label
        color: Theme.fgDim
        font.family: Style.fontFamily
        font.pixelSize: Style.fontBody
      }
    }

    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: value
      color: valueColor
      font.family: Style.fontFamily
      font.pixelSize: Style.fontBody
    }
  }

  component MetricCard: Rectangle {
    default property alias content: cardColumn.data
    width: parent.width
    height: cardColumn.implicitHeight + Style.space * 2
    radius: Style.radiusSmall
    color: Theme.alpha(Theme.fg, Style.cardAlpha)
    border.width: 1
    border.color: Theme.alpha(Theme.fg, Style.cardBorderAlpha)

    Column {
      id: cardColumn
      x: 10
      y: Style.space
      width: parent.width - 20
      spacing: Style.spaceTight
    }
  }

  MetricCard {
    StatRow {
      iconName: "cpu"
      label: "CPU"
      value: SystemStats.cpu + "%"
    }

    StatGraph {
      values: SystemStats.cpuHistory
      lineColor: Theme.accent
    }
  }

  MetricCard {
    StatRow {
      iconName: "memory-stick"
      label: "Memory"
      value: SystemStats.mem + "%  ·  " + panel.formatGb(SystemStats.memUsedGb) + " / " + panel.formatGb(SystemStats.memTotalGb) + " GB"
    }

    StatGraph {
      values: SystemStats.memHistory
      lineColor: Theme.accentAlt
    }
  }

  MetricCard {
    StatRow {
      iconName: "thermometer"
      label: "Temperature"
      value: SystemStats.temp + "°C"
      valueColor: SystemStats.temp >= 80 ? Theme.urgent : Theme.fg
    }

    StatGraph {
      values: SystemStats.tempHistory
      lineColor: Theme.urgent
    }
  }

  MetricCard {
    StatRow {
      iconName: "arrow-down"
      iconColor: Theme.info
      label: "Down" + (SystemStats.netIface.length > 0 ? "  ·  " + SystemStats.netIface : "")
      value: panel.formatSpeed(SystemStats.netDown)
    }

    StatRow {
      iconName: "arrow-up"
      iconColor: Theme.accentAlt
      label: "Up"
      value: panel.formatSpeed(SystemStats.netUp)
    }

    StatGraph {
      values: SystemStats.netDownHistory
      secondValues: SystemStats.netUpHistory
      lineColor: Theme.info
      secondColor: Theme.accentAlt
      maxValue: 0
    }
  }

  MetricCard {
    visible: Nvidia.present

    StatRow {
      iconName: "gpu"
      label: "GPU" + (Nvidia.awake ? "  ·  " + Nvidia.name : "")
      value: Nvidia.awake ? Nvidia.util + "%" : "asleep"
      valueColor: Nvidia.awake ? Theme.fg : Theme.fgDim
    }

    StatGraph {
      values: Nvidia.utilHistory
      lineColor: Theme.success
    }
  }

  CollapsibleSection {
    id: gpuDetails
    visible: Nvidia.awake
    title: "GPU details"
    value: Nvidia.temp + "°C" + (Nvidia.powerDraw >= 0 ? "  ·  " + Math.round(Nvidia.powerDraw) + " W" : "")

    StatRow {
      iconName: "memory-stick"
      label: "Video memory"
      value: Nvidia.memPercent + "%  ·  " + panel.formatVram(Nvidia.memUsedMb) + " / " + panel.formatVram(Nvidia.memTotalMb) + " GB"
    }

    StatRow {
      iconName: "thermometer"
      label: "Temperature"
      value: Nvidia.temp + "°C"
      valueColor: Nvidia.temp >= 85 ? Theme.urgent : Theme.fg
    }

    StatRow {
      visible: Nvidia.powerDraw >= 0
      iconName: "zap"
      label: "Power"
      value: Nvidia.powerDraw.toFixed(1) + (Nvidia.powerLimit >= 0 ? " / " + Math.round(Nvidia.powerLimit) : "") + " W"
    }

    StatRow {
      visible: Nvidia.fan >= 0
      iconName: "fan"
      label: "Fan"
      value: Math.round(Nvidia.fan) + "%"
    }

    StatRow {
      iconName: "activity"
      label: "Clocks"
      value: Nvidia.clockSm + " / " + Nvidia.clockSmMax + " MHz  ·  " + Nvidia.clockMem + " MHz"
    }

    StatRow {
      visible: Nvidia.encUtil > 0 || Nvidia.decUtil > 0
      iconName: "video"
      label: "Encode / decode"
      value: Nvidia.encUtil + "% / " + Nvidia.decUtil + "%"
    }

    StatRow {
      iconName: "cable"
      label: "Link"
      value: "PCIe " + Nvidia.linkGen + " x" + Nvidia.linkWidth + "  ·  " + Nvidia.pstate
    }

    SectionHeader {
      text: "GPU processes"
    }

    Text {
      width: parent.width
      visible: Nvidia.processes.length === 0
      text: "Nothing is using the card"
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontBody
    }

    Repeater {
      model: Nvidia.processes

      StatRow {
        required property var modelData
        label: modelData.name + "  (" + modelData.kind + ")"
        value: modelData.memMb + " MB"
      }
    }
  }

  SectionHeader {
    text: "Top processes"
  }

  Column {
    width: parent.width
    spacing: Style.spaceHair

    Repeater {
      model: panel.topProcesses

      StatRow {
        required property var modelData
        label: modelData.name
        value: modelData.cpu + "%  ·  " + panel.formatMib(modelData.memMib)
      }
    }
  }

  Process {
    id: topProc
    command: ["sh", "-c", "LC_ALL=C top -b -n 2 -d 1 -o %CPU -e m -w 512 | awk '/^top -/ { n++ } n == 2 && $1 ~ /^[0-9]+$/' | head -3"]
    stdout: StdioCollector {
      onStreamFinished: panel.parseTopProcesses(text)
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: topProc.running = true
  }

  Timer {
    interval: 3000
    running: Nvidia.present && gpuDetails.open
    repeat: true
    triggeredOnStart: true
    onTriggered: Nvidia.refreshProcesses()
  }

  Component.onCompleted: gpuDetails.open = Nvidia.util >= 20
}
