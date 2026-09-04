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

  Rectangle {
    width: parent.width
    implicitHeight: vpnRow.implicitHeight + 20
    height: implicitHeight
    radius: Style.radiusSmall
    color: Theme.alpha(Theme.fg, Style.cardAlpha)
    border.width: 1
    border.color: Theme.alpha(Theme.fg, Style.cardBorderAlpha)

    Row {
      id: vpnRow
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 10
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space

      Icon {
        anchors.verticalCenter: parent.verticalCenter
        size: Style.iconLarge
        name: Vpn.connected ? "shield-check" : "shield"
        color: Vpn.connected ? Theme.success : Theme.fgDim
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spaceHair

        Text {
          text: Vpn.connected ? "Connected" : "Not connected"
          color: Theme.fg
          font.family: Style.fontFamily
          font.pixelSize: Style.fontTitle
          font.bold: true
        }

        Text {
          text: "openconnect  ·  gp-vpn"
          color: Theme.fgDim
          font.family: Style.fontFamily
          font.pixelSize: Style.fontCaption
        }
      }
    }
  }
}
