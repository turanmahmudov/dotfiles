import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Square button for one session command. It closes the panel before it runs.
Rectangle {
  id: root

  property var controller: null
  property string iconName: ""
  property string label: ""
  property string command: ""
  property bool danger: false

  implicitHeight: 46
  height: implicitHeight
  radius: Style.radiusSmall
  color: area.containsMouse
    ? (root.danger ? Theme.alpha(Theme.error, 0.12) : Theme.alpha(Theme.fg, 0.12))
    : Theme.alpha(Theme.fg, 0.035)
  border.width: 1
  border.color: area.containsMouse && root.danger
    ? Theme.alpha(Theme.error, 0.28)
    : Theme.alpha(Theme.fg, 0.12)

  function runCommand() {
    if (root.controller)
      root.controller.close()
    Quickshell.execDetached(["sh", "-c", root.command])
  }

  Column {
    anchors.centerIn: parent
    spacing: 3

    Icon {
      anchors.horizontalCenter: parent.horizontalCenter
      size: 16
      name: root.iconName
      color: area.containsMouse
        ? (root.danger ? Theme.error : Theme.fg)
        : Theme.fgDim
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.label
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 6
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.runCommand()
  }
}
