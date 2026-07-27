import QtQuick
import qs.Services
import qs.Ui

Tile {
  iconName: "keyboard"
  label: Hypr.kbLayout
  sublabel: Hypr.kbLayoutFull
  onTriggered: Kb.cycleNext()
}
