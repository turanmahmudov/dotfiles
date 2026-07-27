import QtQuick
import qs.Commons

// Bordered container for InfoRow children, which draw their own separators.
Item {
  id: root
  default property alias content: col.data

  width: parent ? parent.width : implicitWidth
  implicitHeight: col.implicitHeight
  height: implicitHeight

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusSmall
    color: Theme.alpha(Theme.fg, 0.035)
    border.width: 1
    border.color: Theme.alpha(Theme.fg, 0.12)
  }

  Column {
    id: col
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 1
  }
}
