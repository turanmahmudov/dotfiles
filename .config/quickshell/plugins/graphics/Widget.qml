import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  shown: Prime.available
  tooltipText: Prime.logoutNeeded
    ? ("Graphics: " + Prime.resolveLabel(Prime.mode) + "\n"
       + Prime.resolveLabel(Prime.pendingMode) + " after you log out")
    : ("Graphics: " + Prime.resolveLabel(Prime.mode))
  onClicked: openPanel()

  Row {
    spacing: Style.spaceTight

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      name: Prime.resolveIcon(Prime.mode)
      color: {
        if (Prime.logoutNeeded)
          return Theme.warning
        if (root.hovered)
          return Theme.fgDim
        return Prime.mode === "nvidia" ? Theme.accent : Theme.fg
      }
    }
  }
}
