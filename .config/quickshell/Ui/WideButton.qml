import QtQuick
import qs.Commons

Rectangle {
  id: root
  property string label: ""
  signal clicked()

  width: parent ? parent.width : implicitWidth
  implicitHeight: 36
  height: implicitHeight
  radius: Style.radiusSmall
  color: Theme.alpha(Theme.fg, area.containsMouse ? 0.12 : 0.06)

  Text {
    anchors.centerIn: parent
    text: root.label
    color: Theme.fg
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize - 1
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
