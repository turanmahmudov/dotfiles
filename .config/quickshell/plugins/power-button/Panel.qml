import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Popup {
  id: panel
  pluginId: "shell.power-button"
  title: "Session"
  cardWidth: 220

  function act(cmd) {
    Quickshell.execDetached(["sh", "-c", cmd])
    if (controller)
      controller.hide(pluginId)
  }

  Repeater {
    model: [
      { "icon": "lock", "label": "Lock", "cmd": "loginctl lock-session $XDG_SESSION_ID" },
      { "icon": "moon", "label": "Suspend", "cmd": "systemctl suspend" },
      { "icon": "log-out", "label": "Log out", "cmd": "hyprctl dispatch \"hl.dsp.exit()\"" },
      { "icon": "rotate-cw", "label": "Reboot", "cmd": "systemctl reboot" },
      { "icon": "power", "label": "Shut down", "cmd": "systemctl poweroff" }
    ]

    delegate: Rectangle {
      id: rowItem
      required property var modelData
      width: parent.width
      height: 36
      radius: Style.radiusSmall
      color: rowArea.containsMouse ? Theme.alpha(Theme.fg, 0.12) : Theme.alpha(Theme.fg, 0.06)

      Row {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Icon {
          anchors.verticalCenter: parent.verticalCenter
          name: rowItem.modelData.icon
          color: Theme.fg
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: rowItem.modelData.label
          color: Theme.fg
          font.family: Style.fontFamily
          font.pixelSize: Style.fontSize
        }
      }

      MouseArea {
        id: rowArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: panel.act(rowItem.modelData.cmd)
      }
    }
  }
}
