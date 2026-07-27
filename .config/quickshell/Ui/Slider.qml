import QtQuick
import qs.Commons

Item {
  id: slider
  property real value: 0
  property real stepSize: 0.05
  // A slider inside a scrolling form must not eat the wheel, or scrolling past it
  // changes the value instead of moving the page.
  property bool wheelEnabled: true
  signal moved(real value)

  implicitHeight: 18
  implicitWidth: 160

  function setFromX(px) {
    var v = Math.max(0, Math.min(1, px / slider.width))
    slider.value = v
    slider.moved(v)
  }

  function step(dir) {
    var v = Math.max(0, Math.min(1, slider.value + dir * slider.stepSize))
    slider.value = v
    slider.moved(v)
  }

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 6
    radius: 3
    color: Theme.alpha(Theme.fg, 0.15)

    Rectangle {
      width: parent.width * slider.value
      height: parent.height
      radius: 3
      color: Theme.accent
    }
  }

  Rectangle {
    width: 14
    height: 14
    radius: 7
    color: Theme.accent
    y: (parent.height - height) / 2
    x: Math.max(0, Math.min(slider.width - width, slider.value * slider.width - width / 2))
  }

  MouseArea {
    anchors.fill: parent
    onPressed: (m) => slider.setFromX(m.x)
    onPositionChanged: (m) => {
      if (pressed)
        slider.setFromX(m.x)
    }
    onWheel: (w) => {
      if (!slider.wheelEnabled) {
        w.accepted = false
        return
      }
      slider.step(w.angleDelta.y > 0 ? 1 : -1)
    }
  }
}
