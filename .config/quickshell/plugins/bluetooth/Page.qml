import QtQuick
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "Bluetooth"
  hasSwitch: true
  switchOn: Bt.powered
  onSwitchToggled: Bt.togglePower()

  Item {
    width: parent.width
    height: btHeader.implicitHeight

    SectionHeader {
      id: btHeader
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      topPadding: 0
      bottomPadding: 0
      text: "Devices"
    }

    Icon {
      id: btScanIcon
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      size: Style.iconSmall
      name: "refresh-cw"
      transformOrigin: Item.Center
      color: (btScan.containsMouse || Bt.scanning) ? Theme.accent : Theme.fgDim

      RotationAnimator on rotation {
        running: Bt.scanning
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 900
        onRunningChanged: if (!running) btScanIcon.rotation = 0
      }

      MouseArea {
        id: btScan
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Bt.scan()
      }
    }
  }

  Placeholder {
    visible: devList.count === 0
    busy: Bt.scanning
    text: {
      if (!Bt.powered)
        return "Bluetooth is off"
      return Bt.scanning ? "Looking for devices…" : "No devices found"
    }
  }

  Column {
    width: parent.width
    spacing: Style.spaceTight

    Repeater {
      id: devList
      model: Bt.devices

      delegate: ListRow {
        id: devRow
        required property var modelData

        readonly property bool hasBattery: modelData.connected && modelData.batteryAvailable
        readonly property int batteryPercent: Math.round(modelData.battery <= 1
          ? modelData.battery * 100 : modelData.battery)
        readonly property bool lowBattery: hasBattery && batteryPercent <= 20

        iconName: modelData.connected ? "bluetooth-connected" : "bluetooth"
        label: modelData.name || modelData.address
        active: modelData.connected
        value: {
          if (devRow.hasBattery)
            return devRow.batteryPercent + "%"
          if (devRow.modelData.connected)
            return "Connected"
          if (devRow.modelData.pairing)
            return "Pairing…"
          return devRow.modelData.paired ? "" : "New"
        }
        valueColor: devRow.lowBattery ? Theme.urgent : (devRow.active ? Theme.accent : Theme.fgDim)
        valueIconName: devRow.hasBattery ? Icons.battery(devRow.batteryPercent, false) : ""
        valueIconColor: devRow.lowBattery ? Theme.urgent : Theme.accent
        onClicked: Bt.activate(devRow.modelData)
        onRightClicked: if (devRow.modelData.paired) Bt.forget(devRow.modelData)
      }
    }
  }
}
