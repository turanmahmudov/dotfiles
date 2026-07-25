import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  tooltipText: "Session"
  onClicked: openPanel()

  Icon {
    name: "power"
    color: root.hovered ? Theme.fgDim : Theme.fg
  }
}
