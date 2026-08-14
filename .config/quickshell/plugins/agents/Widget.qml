import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  tooltipText: Agents.summary
  onClicked: openPanel()

  Icon {
    name: Agents.waiting ? "bot-message-square" : "bot"
    color: Agents.waiting ? Theme.accent : (root.hovered ? Theme.fgDim : Theme.fg)
  }
}
