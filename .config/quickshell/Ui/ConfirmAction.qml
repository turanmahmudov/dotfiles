import QtQuick
import qs.Commons

// Full width action that asks twice. The second press has a short window, so an
// action that cannot be undone is never one stray click away.
Rectangle {
  id: root

  property string label: ""
  property string confirmLabel: "Tap again to confirm"
  property bool danger: true

  signal confirmed()

  readonly property bool armed: armTimer.running

  width: parent ? parent.width : implicitWidth
  implicitHeight: 34
  height: implicitHeight
  radius: Style.radiusSmall
  color: root.armed
    ? Theme.alpha(root.danger ? Theme.error : Theme.accent, area.containsMouse ? 0.3 : 0.2)
    : Theme.alpha(Theme.fg, area.containsMouse ? 0.12 : 0.05)
  border.width: 1
  border.color: root.armed
    ? Theme.alpha(root.danger ? Theme.error : Theme.accent, 0.45)
    : Theme.alpha(Theme.fg, 0.14)

  Timer {
    id: armTimer
    interval: 3000
  }

  Text {
    anchors.centerIn: parent
    text: root.armed ? root.confirmLabel : root.label
    color: root.armed ? (root.danger ? Theme.error : Theme.accent) : Theme.fg
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize - 4
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (root.armed) {
        armTimer.stop()
        root.confirmed()
        return
      }
      armTimer.restart()
    }
  }
}
