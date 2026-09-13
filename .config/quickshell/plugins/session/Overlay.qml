import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Ui

PanelWindow {
  id: dialog

  readonly property bool active: Session.asking
  property var dialogScreen: null

  function refocus() {
    keys.forceActiveFocus()
  }

  onActiveChanged: {
    if (dialog.active) {
      dialog.dialogScreen = Hypr.focusedScreen
      Qt.callLater(dialog.refocus)
    }
  }

  visible: dialog.active
  screen: dialog.dialogScreen
  color: "transparent"
  WlrLayershell.namespace: "quickshell-session"
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
      onClicked: Session.cancel()
    }
  }

  Item {
    id: keys
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: Session.cancel()
    Keys.onReturnPressed: Session.confirm()
    Keys.onEnterPressed: Session.confirm()
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: 400
    implicitHeight: col.implicitHeight + 40
    height: implicitHeight
    radius: Style.radius
    color: Theme.alpha(Theme.bg, Style.surfaceAlpha)
    border.width: 1
    border.color: Theme.alpha(Theme.fg, 0.15)

    Column {
      id: col
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 20
      spacing: 14

      Row {
        spacing: Style.spaceLoose

        Icon {
          anchors.verticalCenter: parent.verticalCenter
          size: Style.iconLarge
          name: Session.iconName
          color: Session.danger ? Theme.error : Theme.accent
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: Session.label
          color: Theme.fg
          font.family: Style.fontFamily
          font.pixelSize: Style.fontTitle
          font.bold: true
        }
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: Session.message
        color: Theme.fgDim
        font.family: Style.fontFamily
        font.pixelSize: Style.fontTitle
      }

      Row {
        anchors.right: parent.right
        spacing: Style.space

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
            font.pixelSize: Style.fontTitle
          }

          MouseArea {
            id: cancelMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Session.cancel()
          }
        }

        Rectangle {
          width: Math.max(124, confirmLabel.implicitWidth + 32)
          height: 34
          radius: Style.radiusSmall
          color: {
            var tone = Session.danger ? Theme.error : Theme.accent
            return confirmMouse.containsMouse ? Qt.lighter(tone, 1.15) : tone
          }

          Text {
            id: confirmLabel
            anchors.centerIn: parent
            text: Session.label
            color: Theme.bg
            font.family: Style.fontFamily
            font.pixelSize: Style.fontTitle
            font.bold: true
          }

          MouseArea {
            id: confirmMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Session.confirm()
          }
        }
      }
    }
  }
}
