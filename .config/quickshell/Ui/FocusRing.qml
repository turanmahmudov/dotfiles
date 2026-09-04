import QtQuick
import qs.Commons

// Marks the item that holds keyboard focus. Drawn as an overlay so it never
// takes part in the layout of the row it belongs to.
Rectangle {
  property Item target: parent

  anchors.fill: parent
  anchors.margins: -2
  radius: Style.radiusSmall + 2
  color: "transparent"
  border.width: 2
  border.color: Theme.alpha(Theme.accent, 0.7)
  visible: !!target && target.activeFocus
  z: 10
}
