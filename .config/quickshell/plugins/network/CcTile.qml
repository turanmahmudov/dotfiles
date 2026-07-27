import QtQuick
import qs.Commons
import qs.Ui

Tile {
  id: root

  property var controller: null
  property string pluginId: ""

  iconName: Icons.wifi(Network.state, Network.signalStrength)
  label: "Wi-Fi"
  sublabel: Network.state === "ethernet"
    ? "Ethernet"
    : (Network.wifiEnabled ? (Network.ssid.length > 0 ? Network.ssid : "Not connected") : "Off")
  active: Network.wifiEnabled || Network.state === "ethernet"
  hasDetail: true
  onTriggered: Network.toggleWifi()
  onDetailRequested: if (root.controller) root.controller.go(root.pluginId)
}
