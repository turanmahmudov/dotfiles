import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import qs.Commons
import qs.Services
import qs.Ui

PanelWindow {
  id: dialog

  readonly property var flow: agent.flow
  readonly property bool active: agent.isActive && flow !== null
  property real shakeX: 0
  property var dialogScreen: null

  function submit() {
    if (dialog.flow && dialog.flow.isResponseRequired)
      dialog.flow.submit(pwInput.text)
  }

  function cancel() {
    if (dialog.flow)
      dialog.flow.cancelAuthenticationRequest()
  }

  function refocus() {
    pwInput.forceActiveFocus()
  }

  PolkitAgent {
    id: agent
  }

  onActiveChanged: {
    if (active) {
      dialog.dialogScreen = Hypr.focusedScreen
      pwInput.text = ""
      Qt.callLater(refocus)
    }
  }

  Connections {
    target: dialog.flow
    ignoreUnknownSignals: true
    function onFailedChanged() {
      if (dialog.flow && dialog.flow.failed) {
        pwInput.text = ""
        shake.restart()
        Qt.callLater(dialog.refocus)
      }
    }
    function onIsResponseRequiredChanged() {
      pwInput.text = ""
      Qt.callLater(dialog.refocus)
    }
  }

  visible: dialog.active
  screen: dialog.dialogScreen
  color: "transparent"
  WlrLayershell.namespace: "quickshell-polkit"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  exclusiveZone: 0
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.5)

    MouseArea {
      anchors.fill: parent
      onClicked: dialog.refocus()
    }
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: dialog.shakeX
    width: 400
    implicitHeight: col.implicitHeight + 40
    height: implicitHeight
    radius: Style.radius
    color: Theme.alpha(Theme.bg, Style.surfaceAlpha)
    border.width: 1
    border.color: (dialog.flow && dialog.flow.failed) ? Theme.error : Theme.alpha(Theme.fg, 0.15)

    Column {
      id: col
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 20
      spacing: 14

      Row {
        spacing: 12

        Icon {
          anchors.verticalCenter: parent.verticalCenter
          size: 26
          name: "lock"
          color: (dialog.flow && dialog.flow.failed) ? Theme.error : Theme.accent
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "Authentication required"
          color: Theme.fg
          font.family: Style.fontFamily
          font.pixelSize: Style.fontSize + 2
          font.bold: true
        }
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: dialog.flow ? dialog.flow.message : ""
        color: Theme.fgDim
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize
      }

      Rectangle {
        width: parent.width
        height: 40
        radius: Style.radiusSmall
        color: Theme.alpha(Theme.fg, 0.06)
        border.width: 1
        border.color: pwInput.activeFocus ? Theme.accent : Theme.alpha(Theme.fg, 0.15)

        TextInput {
          id: pwInput
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          verticalAlignment: TextInput.AlignVCenter
          clip: true
          color: Theme.fg
          selectionColor: Theme.alpha(Theme.accent, 0.4)
          selectedTextColor: Theme.fg
          font.family: Style.fontFamily
          font.pixelSize: Style.fontSize
          echoMode: (dialog.flow && dialog.flow.responseVisible) ? TextInput.Normal : TextInput.Password
          passwordCharacter: "•"
          enabled: dialog.active && dialog.flow && dialog.flow.isResponseRequired
          onAccepted: dialog.submit()
          Keys.onEscapePressed: dialog.cancel()

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: pwInput.text.length === 0
            text: (dialog.flow && dialog.flow.inputPrompt) ? dialog.flow.inputPrompt : "Password"
            color: Theme.fgDim
            font: pwInput.font
          }
        }
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        visible: text.length > 0
        text: {
          if (dialog.flow && dialog.flow.supplementaryMessage)
            return dialog.flow.supplementaryMessage
          if (dialog.flow && dialog.flow.failed)
            return "Authentication failed. Try again."
          return ""
        }
        color: (dialog.flow && (dialog.flow.supplementaryIsError || dialog.flow.failed)) ? Theme.error : Theme.fgDim
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize - 2
      }

      Row {
        anchors.right: parent.right
        spacing: 8

        Rectangle {
          width: 96
          height: 34
          radius: Style.radiusSmall
          color: cancelMouse.containsMouse ? Theme.alpha(Theme.fg, 0.12) : Theme.alpha(Theme.fg, 0.06)

          Text {
            anchors.centerIn: parent
            text: "Cancel"
            color: Theme.fg
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
          }

          MouseArea {
            id: cancelMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: dialog.cancel()
          }
        }

        Rectangle {
          width: 124
          height: 34
          radius: Style.radiusSmall
          color: authMouse.containsMouse ? Theme.accentAlt : Theme.accent

          Text {
            anchors.centerIn: parent
            text: "Authenticate"
            color: Theme.bg
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
            font.bold: true
          }

          MouseArea {
            id: authMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: dialog.submit()
          }
        }
      }
    }
  }

  SequentialAnimation {
    id: shake
    NumberAnimation {
      target: dialog
      property: "shakeX"
      to: -10
      duration: 40
    }
    NumberAnimation {
      target: dialog
      property: "shakeX"
      to: 10
      duration: 60
    }
    NumberAnimation {
      target: dialog
      property: "shakeX"
      to: 0
      duration: 50
    }
  }
}
