import QtQuick
import qs.Ui

Tile {
  id: root

  property var controller: null
  property string pluginId: ""

  iconName: Bt.powered ? (Bt.connectedCount > 0 ? "bluetooth-connected" : "bluetooth") : "bluetooth-off"
  label: "Bluetooth"
  sublabel: Bt.powered ? (Bt.connectedCount > 0 ? (Bt.connectedCount + " connected") : "On") : "Off"
  active: Bt.powered
  hasDetail: true
  onTriggered: Bt.togglePower()
  onDetailRequested: if (root.controller) root.controller.go(root.pluginId)
}
