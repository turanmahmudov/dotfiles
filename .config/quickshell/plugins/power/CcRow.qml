import QtQuick
import qs.Commons
import qs.Ui

InfoRow {
  id: root

  property var controller: null
  property string pluginId: ""

  readonly property string shortProfile: {
    if (Battery.profile === "power-saver")
      return "Saver"
    if (Battery.profile === "performance")
      return "Performance"
    return "Balanced"
  }

  iconName: Icons.battery(Battery.percent, Battery.charging)
  label: "Battery"
  sublabel: Battery.timeSummary.length > 0 ? Battery.timeSummary : (Battery.charging ? "Charging" : "On battery")
  value: Battery.present ? (Battery.percent + "%  ·  " + root.shortProfile) : root.shortProfile
  onClicked: if (root.controller) root.controller.go(root.pluginId)
}
