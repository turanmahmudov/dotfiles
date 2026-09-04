import QtQuick
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "Wi-Fi"
  hasSwitch: true
  switchOn: Network.wifiEnabled
  onSwitchToggled: Network.toggleWifi()

  property string passwordSsid: ""

  function activate(net) {
    if (net.connected) {
      Network.disconnectWifi()
      return
    }
    if (net.known || !Network.isSecured(net)) {
      Network.connectKnown(net)
      return
    }
    panel.passwordSsid = (panel.passwordSsid === net.name) ? "" : net.name
  }

  // Scanning only while the panel is open; NetworkManager pushes updates.
  Component.onCompleted: Network.setScannerEnabled(true)
  Component.onDestruction: Network.setScannerEnabled(false)

  Row {
    width: parent.width
    spacing: Style.space

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      size: Style.iconLarge
      name: Icons.wifi(Network.state, Network.signalStrength)
      color: Network.state === "disconnected" ? Theme.fgDim : Theme.accent
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.spaceHair

      Text {
        text: Network.state === "ethernet" ? "Ethernet" : (Network.state === "wifi" ? Network.ssid : "Disconnected")
        color: Theme.fg
        font.family: Style.fontFamily
        font.pixelSize: Style.fontTitle
        font.bold: true
      }

      Text {
        visible: Network.ipAddress.length > 0
        text: Network.ipAddress
        color: Theme.fgDim
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
      }
    }
  }

  Item {
    width: parent.width
    height: netHeader.implicitHeight

    SectionHeader {
      id: netHeader
      anchors.left: parent.left
      anchors.top: parent.top
      topPadding: Style.space
      bottomPadding: 0
      text: "Networks"
    }

    Icon {
      id: netScanIcon
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      size: Style.iconSmall
      name: "refresh-cw"
      transformOrigin: Item.Center
      color: (netScan.containsMouse || Network.scanning) ? Theme.accent : Theme.fgDim

      RotationAnimator on rotation {
        running: Network.scanning
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 900
        onRunningChanged: if (!running) netScanIcon.rotation = 0
      }

      MouseArea {
        id: netScan
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Network.requestScan()
      }
    }
  }

  Placeholder {
    visible: netList.count === 0
    busy: Network.scanning
    text: Network.scanning ? "Scanning…" : "No networks found"
  }

  Column {
    width: parent.width
    spacing: Style.spaceTight

    Repeater {
      id: netList
      model: Network.networks

      delegate: Column {
        id: netRow
        required property var modelData
        readonly property bool secured: Network.isSecured(modelData)
        width: parent.width
        spacing: Style.spaceTight

        ListRow {
          iconName: Icons.wifi("wifi", Math.round(netRow.modelData.signalStrength * 100))
          label: netRow.modelData.name
          active: netRow.modelData.connected
          value: {
            if (netRow.modelData.stateChanging)
              return "…"
            if (netRow.modelData.connected)
              return "Connected"
            return netRow.modelData.known ? "Saved" : ""
          }
          valueColor: Theme.fgDim
          valueIconName: netRow.secured ? "shield" : ""
          valueIconColor: Theme.fgDim
          onClicked: panel.activate(netRow.modelData)
          onRightClicked: if (netRow.modelData.known) Network.forget(netRow.modelData)
        }

        Rectangle {
          width: parent.width
          height: 34
          radius: Style.radiusSmall
          color: Theme.alpha(Theme.fg, Style.cardAlpha)
          visible: panel.passwordSsid === netRow.modelData.name

          TextInput {
            id: pwInput
            anchors.left: parent.left
            anchors.right: goBtn.left
            anchors.leftMargin: 10
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            echoMode: TextInput.Password
            color: Theme.fg
            font.family: Style.fontFamily
            font.pixelSize: Style.fontBody
            clip: true
            focus: parent.visible
            onVisibleChanged: if (visible) forceActiveFocus()
            onAccepted: {
              Network.connectWithPassword(netRow.modelData, text)
              text = ""
              panel.passwordSsid = ""
            }

            Text {
              anchors.fill: parent
              verticalAlignment: Text.AlignVCenter
              visible: pwInput.text.length === 0
              text: "Password…"
              color: Theme.fgDim
              font: pwInput.font
            }
          }

          Icon {
            id: goBtn
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            size: Style.iconSmall
            name: "check-check"
            color: Theme.accent
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Network.connectWithPassword(netRow.modelData, pwInput.text)
                pwInput.text = ""
                panel.passwordSsid = ""
              }
            }
          }
        }
      }
    }
  }
}
