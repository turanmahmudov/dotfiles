import QtQuick
import qs.Ui

Tile {
  id: root

  property var controller: null
  property string pluginId: ""

  iconName: "moon"
  // The small tile has no room for a sublabel, so it carries the temperature in
  // the label instead.
  label: (root.compact && NightLight.enabled) ? (NightLight.temperature + "K") : "Night light"
  sublabel: NightLight.enabled ? (NightLight.temperature + "K") : "Off"
  active: NightLight.enabled
  hasDetail: true
  onTriggered: NightLight.toggle()
  onDetailRequested: if (root.controller) root.controller.go(root.pluginId)
}
