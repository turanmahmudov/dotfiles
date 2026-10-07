import QtQuick
import qs.Ui

InfoRow {
  id: root

  property var controller: null
  property string pluginId: ""

  property bool shown: Prime.available

  iconName: Prime.resolveIcon(Prime.mode)
  label: "Graphics"
  value: Prime.logoutNeeded ? (Prime.resolveLabel(Prime.pendingMode) + " after logout") : Prime.resolveLabel(Prime.mode)
  onClicked: if (root.controller) root.controller.go(root.pluginId)
}
