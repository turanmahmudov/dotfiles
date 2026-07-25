import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  function summary() {
    var parts = []
    for (var i = 0; i < Monitors.list.length; i++) {
      var m = Monitors.list[i]
      if (m.disabled)
        continue
      parts.push(m.name + " " + m.width + "×" + m.height + "@" + m.refreshRate)
    }
    return parts.length > 0 ? parts.join("  ·  ") : "No active displays"
  }

  tooltipText: summary()
  onClicked: openPanel()

  Icon {
    name: "monitor"
    color: root.hovered ? Theme.fgDim : Theme.fg
  }
}
