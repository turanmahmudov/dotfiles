import QtQuick
import qs.Ui

InfoRow {
  id: root

  property var controller: null
  property string pluginId: ""

  iconName: Usbg.blockedCount > 0 ? "lock" : "shield-check"
  label: "USB devices"
  sublabel: "Device authorization"
  value: Usbg.blockedCount > 0 ? (Usbg.blockedCount + " blocked") : "All allowed"
  onClicked: if (root.controller) root.controller.go(root.pluginId)
}
