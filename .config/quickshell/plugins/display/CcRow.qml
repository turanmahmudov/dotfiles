import QtQuick
import qs.Ui

InfoRow {
  id: root

  property var controller: null
  property string pluginId: ""

  iconName: "monitor"
  label: "Display"
  sublabel: "Monitors and night light"
  value: NightLight.enabled ? "Night light on" : (Monitors.activeCount + " active")
  onClicked: if (root.controller) root.controller.go(root.pluginId)
}
