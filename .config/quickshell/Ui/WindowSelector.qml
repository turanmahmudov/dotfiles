import QtQuick
import qs.Commons

Item {
  id: root

  signal windowSelected(real x, real y, real width, real height)

  property var monitor: null
  property real mouseX: 0
  property real mouseY: 0
  property real selX: 0
  property real selY: 0
  property real selW: 0
  property real selH: 0
  property bool hasHit: false

  property var windows: {
    var mon = root.monitor
    var ws = mon ? mon.activeWorkspace : null
    if (!ws)
      return []
    var tl = ws.toplevels
    if (!tl)
      return []
    return (tl.values !== undefined) ? tl.values : tl
  }

  onMouseXChanged: updateHovered()
  onMouseYChanged: updateHovered()

  function findHit(mx, my) {
    if (!monitor || !monitor.lastIpcObject)
      return null
    var mx0 = monitor.lastIpcObject.x
    var my0 = monitor.lastIpcObject.y
    for (var i = windows.length - 1; i >= 0; i--) {
      var w = windows[i]
      if (!w || !w.lastIpcObject)
        continue
      var wx = w.lastIpcObject.at[0] - mx0
      var wy = w.lastIpcObject.at[1] - my0
      var ww = w.lastIpcObject.size[0]
      var wh = w.lastIpcObject.size[1]
      if (mx >= wx && mx <= wx + ww && my >= wy && my <= wy + wh)
        return { "x": wx, "y": wy, "w": ww, "h": wh }
    }
    return null
  }

  function updateHovered() {
    var hit = findHit(mouseX, mouseY)
    if (!hit) {
      hasHit = false
      return
    }
    hasHit = true
    selX = hit.x; selY = hit.y
    selW = hit.w; selH = hit.h
  }

  Behavior on selX { SpringAnimation { spring: 5; damping: 0.7; epsilon: 0.1 } }
  Behavior on selY { SpringAnimation { spring: 5; damping: 0.7; epsilon: 0.1 } }
  Behavior on selW { SpringAnimation { spring: 5; damping: 0.7; epsilon: 0.1 } }
  Behavior on selH { SpringAnimation { spring: 5; damping: 0.7; epsilon: 0.1 } }

  SelectionMask {
    selX: root.selX; selY: root.selY
    selW: root.selW; selH: root.selH
    active: root.hasHit
    z: 0
  }

  MouseArea {
    anchors.fill: parent
    z: 3
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onPositionChanged: (m) => {
      root.mouseX = m.x
      root.mouseY = m.y
    }
    onClicked: {
      var hit = root.findHit(root.mouseX, root.mouseY)
      if (hit)
        root.windowSelected(hit.x, hit.y, hit.w, hit.h)
    }
  }
}
