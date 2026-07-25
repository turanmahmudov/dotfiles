import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  tooltipText: Notifications.dnd ? "Do not disturb" : (Notifications.unread > 0 ? (Notifications.unread + " notifications") : "No notifications")
  onClicked: openPanel()
  onRightClicked: Notifications.toggleDnd()

  Icon {
    name: Notifications.dnd ? "bell-off" : (Notifications.unread > 0 ? "bell-ring" : "bell")
    color: Notifications.dnd ? Theme.fgDim : (Notifications.unread > 0 ? Theme.accent : (root.hovered ? Theme.fgDim : Theme.fg))
  }
}
