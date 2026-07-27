import QtQuick
import qs.Commons

Item {
  id: root
  property bool checked: false
  signal toggled()

  implicitWidth: 32
  implicitHeight: 18

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: root.checked ? Theme.accent : Theme.alpha(Theme.fg, 0.22)

    Behavior on color {
      ColorAnimation { duration: Style.animFast }
    }
  }

  Rectangle {
    width: 12
    height: 12
    radius: 6
    y: (parent.height - height) / 2
    x: root.checked ? parent.width - width - 3 : 3
    color: root.checked ? Theme.bg : Theme.fgDim

    Behavior on x {
      NumberAnimation { duration: Style.animFast; easing.type: Easing.OutCubic }
    }
  }

  MouseArea {
    anchors.fill: parent
    anchors.margins: -4
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled()
  }
}
