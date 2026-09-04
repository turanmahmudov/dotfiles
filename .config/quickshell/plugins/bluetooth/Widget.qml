import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  tooltipText: Bt.powered
    ? ("Bluetooth: " + Bt.connectedCount + " connected")
    : "Bluetooth: off"
  onClicked: openPanel()
  onRightClicked: Bt.togglePower()

  Row {
    spacing: Style.spaceHair

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      name: Bt.powered
        ? (Bt.connectedCount > 0 ? "bluetooth-connected" : "bluetooth")
        : "bluetooth-off"
      color: root.hovered ? Theme.fgDim : Theme.fg
    }

    Text {
      visible: Bt.connectedCount > 0
      anchors.verticalCenter: parent.verticalCenter
      text: Bt.connectedCount
      color: Theme.accentActive
      font.family: Style.fontFamily
      font.pixelSize: Style.fontCaption
    }
  }
}
