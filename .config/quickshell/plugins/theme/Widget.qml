import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  tooltipText: Themes.family.length > 0
    ? ("Theme: " + Themes.displayName + "  ·  " + Themes.mode)
    : "Theme"
  onClicked: openPanel()
  onRightClicked: Themes.toggleMode()

  Icon {
    name: "palette"
    color: root.hovered ? Theme.fgDim : Theme.fg
  }
}
