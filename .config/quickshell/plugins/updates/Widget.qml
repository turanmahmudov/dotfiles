import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarItem {
  id: root

  shown: Updates.hasUpdates
  tooltipText: Updates.tooltip.length > 0 ? Updates.tooltip : (Updates.count + " updates available")
  onClicked: Quickshell.execDetached(["kitty", "sh", "-c", "sudo apt upgrade; printf '\\nPress Enter to close...'; read _"])

  Row {
    spacing: 6

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      name: "download"
      color: Theme.warning
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Updates.count
      color: Theme.warning
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
    }
  }
}
