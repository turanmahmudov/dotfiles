import QtQuick
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "USB devices"

  Component.onCompleted: Usbg.refresh()

  component ActionButton: Rectangle {
    id: button
    property string label: ""
    property bool strong: false
    signal clicked()

    implicitWidth: caption.implicitWidth + 16
    implicitHeight: 24
    radius: Style.radiusSmall
    color: button.strong
      ? Theme.alpha(Theme.accent, area.containsMouse ? 0.32 : 0.22)
      : Theme.alpha(Theme.fg, area.containsMouse ? 0.14 : 0.07)
    border.width: 1
    border.color: button.strong ? Theme.alpha(Theme.accent, 0.4) : Theme.alpha(Theme.fg, 0.14)

    Text {
      id: caption
      anchors.centerIn: parent
      text: button.label
      color: button.strong ? Theme.accent : Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 5
    }

    MouseArea {
      id: area
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.clicked()
    }
  }

  Column {
    width: parent.width
    spacing: 4

    Repeater {
      model: Usbg.entries

      delegate: Rectangle {
        id: row
        required property var modelData

        width: parent.width
        height: 52
        radius: Style.radiusSmall
        color: row.modelData.blocked ? Theme.alpha(Theme.urgent, 0.12) : Theme.alpha(Theme.fg, 0.04)
        border.width: 1
        border.color: row.modelData.blocked ? Theme.alpha(Theme.urgent, 0.3) : Theme.alpha(Theme.fg, 0.12)

        Icon {
          id: leadIcon
          anchors.left: parent.left
          anchors.leftMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          name: row.modelData.blocked ? "lock" : "check"
          color: row.modelData.blocked ? Theme.urgent : Theme.accent
        }

        Column {
          anchors.left: leadIcon.right
          anchors.leftMargin: 9
          anchors.right: actions.left
          anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          Text {
            width: parent.width
            elide: Text.ElideRight
            text: row.modelData.name
            color: Theme.fg
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize - 3
            font.bold: true
          }

          Text {
            width: parent.width
            elide: Text.ElideRight
            text: {
              if (row.modelData.blocked)
                return "Blocked"
              return row.modelData.saved ? "Allowed always" : "Allowed this session only"
            }
            color: row.modelData.blocked ? Theme.urgent
                 : (row.modelData.saved ? Theme.accent : Theme.fgDim)
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize - 5
          }

          Text {
            width: parent.width
            elide: Text.ElideRight
            text: row.modelData.vidpid + (row.modelData.port.length > 0 ? "  ·  port " + row.modelData.port : "")
            color: Theme.fgDim
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize - 6
          }
        }

        Row {
          id: actions
          anchors.right: parent.right
          anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          spacing: 4

          ActionButton {
            visible: row.modelData.blocked
            label: "Allow once"
            onClicked: Usbg.allowOnce(row.modelData.id)
          }

          ActionButton {
            visible: !row.modelData.saved
            label: "Allow always"
            strong: true
            onClicked: Usbg.allowAlways(row.modelData.id)
          }

          ActionButton {
            visible: !row.modelData.blocked
            label: "Block"
            onClicked: Usbg.blockDevice(row.modelData.id)
          }

          ActionButton {
            visible: row.modelData.saved
            label: "Forget"
            onClicked: Usbg.forgetRule(row.modelData.ruleId)
          }
        }
      }
    }
  }

  Text {
    width: parent.width
    wrapMode: Text.WordWrap
    text: "A new device is blocked until you allow it. Allow once lasts until you unplug it. Allow always saves a rule, works in every port and survives a restart."
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize - 5
  }
}
