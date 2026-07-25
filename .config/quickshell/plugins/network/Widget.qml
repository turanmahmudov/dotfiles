import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  tooltipText: Network.state === "wifi"
    ? (Network.ssid + " (" + Network.signalStrength + "%)")
    : (Network.state === "ethernet" ? "Ethernet" : "Wi-Fi disconnected")
  onClicked: openPanel()
  onRightClicked: Network.toggleWifi()

  Icon {
    name: Icons.wifi(Network.state, Network.signalStrength)
    color: root.hovered ? Theme.fgDim : Theme.fg
  }
}
