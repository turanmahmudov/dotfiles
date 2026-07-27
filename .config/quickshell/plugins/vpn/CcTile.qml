import QtQuick
import qs.Ui

Tile {
  id: root

  property var controller: null
  property string pluginId: ""

  iconName: Vpn.connected ? "shield-check" : "shield"
  label: "VPN"
  sublabel: Vpn.connected ? "Connected" : "Off"
  active: Vpn.connected
  hasDetail: true
  onTriggered: Vpn.toggle()
  onDetailRequested: if (root.controller) root.controller.go(root.pluginId)
}
