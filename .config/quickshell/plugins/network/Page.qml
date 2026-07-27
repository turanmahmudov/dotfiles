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
    spacing: 10

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      size: 26
      name: Icons.wifi(Network.state, Network.signalStrength)
      color: Network.state === "disconnected" ? Theme.fgDim : Theme.accent
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      Text {
        text: Network.state === "ethernet" ? "Ethernet" : (Network.state === "wifi" ? Network.ssid : "Disconnected")
        color: Theme.fg
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize
        font.bold: true
      }

      Text {
        visible: Network.ipAddress.length > 0
        text: Network.ipAddress
        color: Theme.fgDim
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize - 3
      }
    }
  }

  Item {
    width: parent.width
    height: 18

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "Networks"
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 2
    }

    Icon {
      id: netScanIcon
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      size: 15
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

  Column {
    width: parent.width
    spacing: 4

    Repeater {
      id: netList
      model: Network.networks

      delegate: Column {
        id: netRow
        required property var modelData
        readonly property bool secured: Network.isSecured(modelData)
        width: parent.width
        spacing: 4

        Rectangle {
          width: parent.width
          height: 32
          radius: Style.radiusSmall
          color: netRow.modelData.connected ? Theme.alpha(Theme.accent, netRowArea.containsMouse ? 0.28 : 0.2) : Theme.alpha(Theme.fg, netRowArea.containsMouse ? 0.12 : 0.06)

          Icon {
            id: sigIcon
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            size: 16
            name: Icons.wifi("wifi", Math.round(netRow.modelData.signalStrength * 100))
            color: netRow.modelData.connected ? Theme.accent : Theme.fg
          }

          Text {
            anchors.left: sigIcon.right
            anchors.leftMargin: 8
            anchors.right: stateText.left
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: netRow.modelData.name
            color: netRow.modelData.connected ? Theme.accent : Theme.fg
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize - 1
          }

          Text {
            id: stateText
            anchors.right: lockIcon.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: {
              if (netRow.modelData.stateChanging)
                return "…"
              if (netRow.modelData.connected)
                return "Connected"
              return netRow.modelData.known ? "Saved" : ""
            }
            color: Theme.fgDim
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize - 3
          }

          Icon {
            id: lockIcon
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            size: 12
            visible: netRow.secured
            name: "shield"
            color: Theme.fgDim
          }

          MouseArea {
            id: netRowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (m) => {
              if (m.button === Qt.RightButton && netRow.modelData.known)
                Network.forget(netRow.modelData)
              else
                panel.activate(netRow.modelData)
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 34
          radius: Style.radiusSmall
          color: Theme.alpha(Theme.fg, 0.06)
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
            font.pixelSize: Style.fontSize - 1
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
            size: 16
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
