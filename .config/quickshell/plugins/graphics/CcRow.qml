import QtQuick
import qs.Ui

InfoRow {
  id: root

  property var controller: null
  property string pluginId: ""

  property bool shown: Prime.available

  iconName: Prime.resolveIcon(Prime.mode)
  label: "Graphics"
  sublabel: Prime.logoutNeeded ? (Prime.resolveLabel(Prime.pendingMode) + " after logout") : "GPU mode"
  value: Prime.resolveLabel(Prime.mode)
  onClicked: if (root.controller) root.controller.go(root.pluginId)
}
