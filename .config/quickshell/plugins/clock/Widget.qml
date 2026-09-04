import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarItem {
  id: root

  onClicked: openPanel()

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Text {
    text: Qt.formatDateTime(clock.date, (root.settings && root.settings.format) ? root.settings.format : "ddd, MMM d  HH:mm")
    color: Theme.fg
    font.family: Style.fontFamily
    font.pixelSize: Style.fontTitle
    font.bold: true
  }
}
