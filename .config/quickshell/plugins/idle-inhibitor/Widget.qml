import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  tooltipText: KeepAwake.active ? "Keep awake: on" : "Keep awake: off"
  onClicked: KeepAwake.toggle()

  Icon {
    name: KeepAwake.active ? "eye" : "eye-off"
    color: root.hovered ? Theme.fgDim : Theme.fg
  }
}
