import QtQuick
import qs.Commons

// Pill that hosts a horizontal list of BarWidgets.
// Width comes only from the Row — never center the Row in a parent sized by the Row.
Item {
  id: root

  property var entries: []
  property var controller: null
  property var hostScreen: null

  width: row.width + 12
  height: Style.barHeight - 8
  visible: row.width > 0

  Rectangle {
    anchors.fill: parent
    radius: Style.radius
    color: Theme.alpha(Theme.fg, Style.groupBgAlpha)
  }

  Row {
    id: row
    x: 6
    anchors.verticalCenter: parent.verticalCenter
    // BarItem already includes horizontalPadding on each side; extra spacing
    // doubles the gap between group icons.
    spacing: 0

    Repeater {
      model: root.entries

      BarWidget {
        required property var modelData
        entry: modelData
        controller: root.controller
        hostScreen: root.hostScreen
      }
    }
  }
}
