import QtQuick
import qs.Commons

Rectangle {
  id: root
  property string label: ""
  signal clicked()

  activeFocusOnTab: true
  Keys.onReturnPressed: root.clicked()
  Keys.onEnterPressed: root.clicked()
  Keys.onSpacePressed: root.clicked()

  width: parent ? parent.width : implicitWidth
  implicitHeight: 36
  height: implicitHeight
  radius: Style.radiusSmall
  color: Theme.alpha(Theme.fg, area.containsMouse ? Style.cardHoverAlpha : Style.cardAlpha)

    Behavior on color {
      ColorAnimation {
        duration: Style.animFast
      }
    }

  Text {
    anchors.centerIn: parent
    text: root.label
    color: Theme.fg
    font.family: Style.fontFamily
    font.pixelSize: Style.fontBody
  }

  FocusRing {}

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
