import QtQuick
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "VPN"
  hasSwitch: true
  switchOn: Vpn.connected
  onSwitchToggled: Vpn.toggle()

  Component.onCompleted: Vpn.refresh()

  Row {
    width: parent.width
    spacing: 10

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      size: 26
      name: Vpn.connected ? "shield-check" : "shield"
      color: Vpn.connected ? Theme.success : Theme.fgDim
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      Text {
        text: Vpn.connected ? "Connected" : "Not connected"
        color: Theme.fg
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize
        font.bold: true
      }

      Text {
        text: "openconnect  ·  gp-vpn"
        color: Theme.fgDim
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize - 3
      }
    }
  }
}
