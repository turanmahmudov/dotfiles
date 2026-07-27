import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "Software updates"

  function runUpgrade() {
    Quickshell.execDetached(["kitty", "sh", "-c",
      "sudo apt upgrade; printf '\\nPress Enter to close...'; read _"])
    panel.requestClose()
  }

  Text {
    visible: !Updates.hasUpdates
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    topPadding: 10
    bottomPadding: 10
    text: "No updates"
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize - 1
  }

  Text {
    visible: Updates.hasUpdates
    width: parent.width
    wrapMode: Text.WordWrap
    text: Updates.tooltip
    color: Theme.fg
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize - 1
  }

  WideButton {
    visible: Updates.hasUpdates
    label: "Install all updates"
    onClicked: panel.runUpgrade()
  }

  WideButton {
    label: "Check again"
    onClicked: Updates.refresh()
  }
}
