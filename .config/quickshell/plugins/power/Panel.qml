import QtQuick
import qs.Commons
import qs.Ui

Popup {
  id: panel
  pluginId: "shell.power"
  title: "Power"
  cardWidth: 300

  function profileLabel(p) {
    if (p === "power-saver")
      return "Power Saver"
    if (p === "performance")
      return "Performance"
    return "Balanced"
  }

  Row {
    width: parent.width
    spacing: 10
    visible: Battery.present

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      size: 28
      name: Icons.battery(Battery.percent, Battery.charging)
      color: Theme.fg
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      Text {
        text: Battery.percent + "%"
        color: Theme.fg
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize + 2
        font.bold: true
      }

      Text {
        text: {
          var state = Battery.full ? "Fully charged" : (Battery.charging ? "Charging" : "On battery")
          return Battery.timeSummary.length > 0 ? (state + "  ·  " + Battery.timeSummary) : state
        }
        color: Theme.fgDim
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize - 2
      }
    }
  }

  Text {
    text: "Power profile"
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize - 2
  }

  Column {
    width: parent.width
    spacing: 6

    Repeater {
      model: Battery.profiles

      delegate: Rectangle {
        id: pill
        required property var modelData
        readonly property bool active: Battery.profile === modelData
        width: parent.width
        height: 36
        radius: Style.radiusSmall
        color: active ? Theme.alpha(Theme.accent, pillArea.containsMouse ? 0.28 : 0.2) : Theme.alpha(Theme.fg, pillArea.containsMouse ? 0.12 : 0.06)

        Row {
          anchors.left: parent.left
          anchors.leftMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: Icons.profile(pill.modelData)
            color: pill.active ? Theme.accent : Theme.fg
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: panel.profileLabel(pill.modelData)
            color: pill.active ? Theme.accent : Theme.fg
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
          }
        }

        MouseArea {
          id: pillArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Battery.setProfile(pill.modelData)
        }
      }
    }
  }
}
