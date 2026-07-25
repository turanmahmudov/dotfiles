import QtQuick
import qs.Commons
import qs.Ui

Popup {
  id: panel
  pluginId: "shell.bluetooth"
  title: "Bluetooth"
  cardWidth: 320

  Rectangle {
    width: parent.width
    height: 34
    radius: Style.radiusSmall
    color: Bt.powered ? Theme.alpha(Theme.accent, btToggleArea.containsMouse ? 0.28 : 0.2) : Theme.alpha(Theme.fg, btToggleArea.containsMouse ? 0.12 : 0.06)

    Row {
      anchors.centerIn: parent
      spacing: 6
      Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: Bt.powered ? "bluetooth" : "bluetooth-off"
        color: Bt.powered ? Theme.accent : Theme.fg
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Bt.powered ? "Bluetooth On" : "Bluetooth Off"
        color: Bt.powered ? Theme.accent : Theme.fg
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize - 1
      }
    }

    MouseArea {
      id: btToggleArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: Bt.togglePower()
    }
  }

  Item {
    width: parent.width
    height: 18

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "Devices"
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 2
    }

    Icon {
      id: btScanIcon
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      size: 15
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

  Column {
    width: parent.width
    spacing: 4

    Repeater {
      id: devList
      model: Bt.devices

      delegate: Rectangle {
        id: devRow
        required property var modelData
        width: parent.width
        height: 32
        radius: Style.radiusSmall
        color: devRow.modelData.connected ? Theme.alpha(Theme.accent, devRowArea.containsMouse ? 0.28 : 0.2) : Theme.alpha(Theme.fg, devRowArea.containsMouse ? 0.12 : 0.06)

        readonly property bool hasBattery: modelData.connected && modelData.batteryAvailable
        readonly property int batteryPercent: Math.round(modelData.battery <= 1 ? modelData.battery * 100 : modelData.battery)
        readonly property bool lowBattery: hasBattery && batteryPercent <= 20

        Text {
          anchors.left: parent.left
          anchors.right: stateInfo.left
          anchors.leftMargin: 10
          anchors.rightMargin: 6
          anchors.verticalCenter: parent.verticalCenter
          elide: Text.ElideRight
          text: devRow.modelData.name || devRow.modelData.address
          color: devRow.modelData.connected ? Theme.accent : Theme.fg
          font.family: Style.fontFamily
          font.pixelSize: Style.fontSize - 1
        }

        Row {
          id: stateInfo
          anchors.right: parent.right
          anchors.rightMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          spacing: 4

          Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: devRow.hasBattery
            name: Icons.battery(devRow.batteryPercent, false)
            color: devRow.lowBattery ? Theme.urgent : Theme.accent
            size: 15
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
              if (devRow.hasBattery)
                return devRow.batteryPercent + "%"
              if (devRow.modelData.connected)
                return "Connected"
              if (devRow.modelData.pairing)
                return "Pairing…"
              return devRow.modelData.paired ? "" : "New"
            }
            color: devRow.lowBattery ? Theme.urgent : Theme.fgDim
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize - 3
          }
        }

        MouseArea {
          id: devRowArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: (m) => {
            if (m.button === Qt.RightButton && devRow.modelData.paired)
              Bt.forget(devRow.modelData)
            else
              Bt.activate(devRow.modelData)
          }
        }
      }
    }
  }
}
