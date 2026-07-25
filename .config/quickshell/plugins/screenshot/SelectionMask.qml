import QtQuick
import qs.Commons

Item {
  id: m
  anchors.fill: parent

  property real selX: 0
  property real selY: 0
  property real selW: 0
  property real selH: 0
  property bool active: false
  property real dimOpacity: 0.55

  Rectangle {
    color: Theme.alpha(Theme.bg, m.dimOpacity)
    x: 0; y: 0
    width: m.width
    height: m.active ? m.selY : m.height
  }
  Rectangle {
    color: Theme.alpha(Theme.bg, m.dimOpacity)
    visible: m.active
    x: 0; y: m.selY + m.selH
    width: m.width
    height: Math.max(0, m.height - (m.selY + m.selH))
  }
  Rectangle {
    color: Theme.alpha(Theme.bg, m.dimOpacity)
    visible: m.active
    x: 0; y: m.selY
    width: m.selX
    height: m.selH
  }
  Rectangle {
    color: Theme.alpha(Theme.bg, m.dimOpacity)
    visible: m.active
    x: m.selX + m.selW; y: m.selY
    width: Math.max(0, m.width - (m.selX + m.selW))
    height: m.selH
  }
  Rectangle {
    z: 1
    visible: m.active && m.selW > 0 && m.selH > 0
    x: m.selX; y: m.selY
    width: m.selW; height: m.selH
    color: "transparent"
    border.color: Theme.accent
    border.width: 2
    radius: 2
  }
}
