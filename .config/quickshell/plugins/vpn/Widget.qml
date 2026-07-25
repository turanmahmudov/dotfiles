import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  tooltipText: Vpn.connected ? "VPN: connected" : "VPN: off"
  onClicked: Vpn.toggle()

  Icon {
    name: Vpn.connected ? "shield-check" : "shield"
    color: Vpn.connected ? Theme.accentActive : (root.hovered ? Theme.fgDim : Theme.fg)
  }
}
