import QtQuick
import qs.Commons

Item {
  id: btn
  property string name: ""
  property color color: Theme.fg
  property int iconSize: Style.iconSize
  property string tooltipText: ""
  property int extraWidth: 8

  signal clicked(var mouse)
  signal rightClicked(var mouse)
  signal scrolledUp
  signal scrolledDown

  readonly property bool hovered: mouse.containsMouse

  implicitWidth: iconSize + extraWidth
  implicitHeight: Style.barHeight - 8

  Icon {
    anchors.centerIn: parent
    name: btn.name
    color: btn.color
    size: btn.iconSize
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (m) => m.button === Qt.RightButton ? btn.rightClicked(m) : btn.clicked(m)
    onWheel: (w) => w.angleDelta.y > 0 ? btn.scrolledUp() : btn.scrolledDown()
  }

  onHoveredChanged: {
    if (btn.hovered && btn.tooltipText.length > 0)
      tipTimer.restart()
    else {
      tipTimer.stop()
      tip.visible = false
    }
  }

  HoverTooltip {
    id: tip
    target: btn
    text: btn.tooltipText
  }

  Timer {
    id: tipTimer
    interval: 500
    onTriggered: if (btn.hovered && btn.tooltipText.length > 0) tip.visible = true
  }
}
