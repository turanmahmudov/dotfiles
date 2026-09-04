import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

PopupWindow {
  id: tip
  property Item target: null
  property string text: ""

  readonly property var targetWin: target ? target.QsWindow.window : null

  visible: false
  color: "transparent"
  implicitWidth: label.implicitWidth + 20
  implicitHeight: label.implicitHeight + 12

  anchor {
    window: tip.targetWin
    rect.width: 1
    rect.height: 1
    edges: Edges.Top | Edges.Left
    gravity: Edges.Bottom | Edges.Right

    onAnchoring: {
      if (!tip.target || !tip.targetWin)
        return
      var localY = Style.barAtTop ? (tip.target.height + 6) : (-tip.implicitHeight - 6)
      var localX = tip.target.width / 2 - tip.implicitWidth / 2
      var p = tip.targetWin.contentItem.mapFromItem(tip.target, localX, localY)
      p.x = Math.max(Style.sideMargin, Math.min(p.x, tip.targetWin.width - tip.implicitWidth - Style.sideMargin))
      tip.anchor.rect.x = Math.round(p.x)
      tip.anchor.rect.y = Math.round(p.y)
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: Style.tooltipRadius
    color: Theme.bg
    border.color: Theme.fg
    border.width: 1

    Text {
      id: label
      anchors.centerIn: parent
      text: tip.text
      color: Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontBody
    }
  }
}
