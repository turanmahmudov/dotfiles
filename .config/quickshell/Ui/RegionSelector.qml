import QtQuick
import qs.Commons

Item {
  id: root

  signal regionSelected(real x, real y, real width, real height)
  signal cancelled()

  property real mouseX: 0
  property real mouseY: 0
  property bool selecting: false
  property real selX: 0
  property real selY: 0
  property real selW: 0
  property real selH: 0
  property point startPos
  property alias pressed: area.pressed

  function clearSelection() {
    selecting = false
    selX = 0; selY = 0; selW = 0; selH = 0
  }

  SelectionMask {
    selX: root.selX; selY: root.selY
    selW: root.selW; selH: root.selH
    active: root.selecting
    z: 0
  }

  Rectangle {
    z: 2
    visible: root.selecting && root.selW > 20
    color: Theme.alpha(Theme.bg, 0.85)
    radius: Style.radiusSmall
    border.color: Theme.alpha(Theme.fg, 0.15)
    border.width: 1
    width: dims.implicitWidth + 16
    height: dims.implicitHeight + 8
    x: Math.max(8, Math.min(root.width - width - 8, root.selX + root.selW / 2 - width / 2))
    y: root.selY - height - 8 > 8 ? root.selY - height - 8 : root.selY + root.selH + 8
    Text {
      id: dims
      anchors.centerIn: parent
      text: Math.round(root.selW) + " × " + Math.round(root.selH)
      color: Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 2
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    z: 3
    hoverEnabled: true
    cursorShape: Qt.CrossCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onPositionChanged: (m) => {
      root.mouseX = m.x
      root.mouseY = m.y
      if (root.selecting && (m.buttons & Qt.LeftButton)) {
        root.selX = Math.min(root.startPos.x, m.x)
        root.selY = Math.min(root.startPos.y, m.y)
        root.selW = Math.abs(m.x - root.startPos.x)
        root.selH = Math.abs(m.y - root.startPos.y)
      }
    }
    onPressed: (m) => {
      if (m.button === Qt.RightButton) {
        root.cancelled()
        return
      }
      root.startPos = Qt.point(m.x, m.y)
      root.selX = m.x; root.selY = m.y
      root.selW = 0; root.selH = 0
      root.selecting = true
    }
    onReleased: (m) => {
      if (m.button === Qt.RightButton)
        return
      if (root.selW < 5 || root.selH < 5) {
        root.clearSelection()
        return
      }
      root.regionSelected(root.selX, root.selY, root.selW, root.selH)
    }
  }
}
