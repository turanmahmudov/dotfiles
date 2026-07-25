import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services

PanelWindow {
  id: toasts

  readonly property int toastDuration: 3000
  readonly property int toastMaxDuration: 5000

  screen: Hypr.focusedScreen
  color: "transparent"
  WlrLayershell.namespace: "quickshell-notifications"
  WlrLayershell.layer: WlrLayer.Overlay
  anchors {
    top: true
    right: true
  }
  margins.top: 10
  margins.right: Style.sideMargin
  exclusiveZone: 0
  implicitWidth: 360
  implicitHeight: Math.max(1, col.implicitHeight)
  visible: Notifications.popups.length > 0

  Column {
    id: col
    width: parent.width
    spacing: 8

    Repeater {
      model: Notifications.popups

      delegate: NotificationCard {
        id: toastCard
        required property var modelData
        notif: modelData
        cardWidth: 360

        HoverHandler {
          id: hover
        }

        Timer {
          interval: (toastCard.modelData && toastCard.modelData.expireTimeout > 0) ? Math.min(toasts.toastMaxDuration, toastCard.modelData.expireTimeout) : toasts.toastDuration
          running: !hover.hovered
          onTriggered: Notifications.removePopup(toastCard.modelData)
        }
      }
    }
  }
}
