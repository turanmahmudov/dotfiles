import QtQuick
import qs.Commons

// Standalone bordered row for lists of things you pick: networks, devices,
// packages, profiles.
Item {
  id: root
  property string iconName: ""
  property string label: ""
  property string sublabel: ""
  property string value: ""
  property bool active: false
  property color valueColor: root.active ? Theme.accent : Theme.fgDim

  signal clicked()
  signal rightClicked()

  width: parent ? parent.width : implicitWidth
  implicitHeight: 44
  height: implicitHeight

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusSmall
    color: root.active
      ? Theme.alpha(Theme.accent, area.containsMouse ? 0.22 : 0.16)
      : Theme.alpha(Theme.fg, area.containsMouse ? 0.09 : 0.04)
    border.width: 1
    border.color: root.active ? Theme.alpha(Theme.accent, 0.3) : Theme.alpha(Theme.fg, 0.12)
  }

  Icon {
    id: leadIcon
    anchors.left: parent.left
    anchors.leftMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    visible: root.iconName.length > 0
    name: root.iconName
    color: root.active ? Theme.accent : Theme.fg
  }

  Text {
    id: valueLabel
    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    text: root.value
    color: root.valueColor
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize - 5
  }

  Column {
    anchors.left: root.iconName.length > 0 ? leadIcon.right : parent.left
    anchors.leftMargin: root.iconName.length > 0 ? 9 : 10
    anchors.right: valueLabel.left
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    spacing: 2

    Text {
      width: parent.width
      elide: Text.ElideRight
      text: root.label
      color: root.active ? Theme.accent : Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 3
      font.bold: true
    }

    Text {
      width: parent.width
      elide: Text.ElideRight
      visible: root.sublabel.length > 0
      text: root.sublabel
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 5
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (m) => m.button === Qt.RightButton ? root.rightClicked() : root.clicked()
  }
}
