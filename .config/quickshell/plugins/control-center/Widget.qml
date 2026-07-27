import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  tooltipText: "Control Center"
  onClicked: openPanel()

  Icon {
    name: "sliders-horizontal"
    color: root.hovered ? Theme.fgDim : Theme.fg
  }
}
