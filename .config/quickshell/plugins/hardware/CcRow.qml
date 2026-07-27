import QtQuick
import qs.Ui

InfoRow {
  id: root

  property var controller: null
  property string pluginId: ""

  iconName: "gauge"
  label: "System health"
  sublabel: SystemStats.temp >= 80 ? "Running hot" : "No warnings"
  value: SystemStats.cpu + "% CPU"
  onClicked: if (root.controller) root.controller.go(root.pluginId)
}
