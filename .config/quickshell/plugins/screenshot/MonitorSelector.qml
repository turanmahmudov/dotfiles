import QtQuick
import qs.Commons

Item {
  id: root

  signal monitorSelected()
  property string label: ""

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.monitorSelected()
  }

  Rectangle {
    anchors.fill: parent
    visible: !area.containsMouse
    color: Theme.alpha(Theme.bg, 0.55)
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: 3
    visible: area.containsMouse
    color: "transparent"
    border.color: Theme.accent
    border.width: 3
    radius: Style.radius
  }

  Rectangle {
    visible: area.containsMouse && root.label.length > 0
    anchors.centerIn: parent
    width: labelText.implicitWidth + 28
    height: labelText.implicitHeight + 18
    radius: Style.radius
    color: Theme.alpha(Theme.bg, Style.surfaceAlpha)
    border.color: Theme.alpha(Theme.fg, 0.15)
    border.width: 1

    Text {
      id: labelText
      anchors.centerIn: parent
      text: root.label
      color: Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
    }
  }
}
