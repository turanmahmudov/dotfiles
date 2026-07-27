import QtQuick
import qs.Ui

InfoRow {
  id: root

  property var controller: null
  property string pluginId: ""

  iconName: "download"
  label: "Software updates"
  sublabel: "System packages"
  value: Updates.hasUpdates ? (Updates.count + " ready") : "Up to date"
  onClicked: if (root.controller) root.controller.go(root.pluginId)
}
