import QtQuick
import qs.Commons

Item {
  id: root

  property var settings: ({})
  property var controller: null
  property var screen: null
  property string pluginId: ""

  default property alias content: contentRow.data
  property bool hovered: interactive && mouse.containsMouse
  property int horizontalPadding: Style.paddingH
  property string tooltipText: ""
  property bool shown: true
  property bool interactive: true

  onHoveredChanged: {
    if (root.hovered && root.tooltipText.length > 0) {
      tipTimer.restart()
    } else {
      tipTimer.stop()
      barTip.visible = false
    }
  }

  HoverTooltip {
    id: barTip
    target: root
    text: root.tooltipText
  }

  Timer {
    id: tipTimer
    interval: 500
    onTriggered: if (root.hovered && root.tooltipText.length > 0) barTip.visible = true
  }

  activeFocusOnTab: root.interactive
  Keys.onReturnPressed: root.clicked(null)
  Keys.onEnterPressed: root.clicked(null)
  Keys.onSpacePressed: root.clicked(null)

  signal clicked(var mouse)
  signal rightClicked(var mouse)
  signal scrolledUp
  signal scrolledDown

  function openPanel() {
    if (controller && pluginId)
      controller.toggleAt(pluginId, root)
  }

  // True while this widget's own page is the one showing in the panel.
  readonly property bool panelOpen: !!(controller && pluginId.length > 0 && controller.page === pluginId)

  implicitWidth: shown ? (contentRow.implicitWidth + 2 * horizontalPadding) : 0
  implicitHeight: Style.barHeight - 10
  width: implicitWidth
  height: implicitHeight
  visible: shown

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusSmall
    opacity: (root.interactive && (root.hovered || root.panelOpen)) ? 1 : 0
    color: Theme.alpha(Theme.fg, root.panelOpen ? Style.cardActiveAlpha : Style.cardHoverAlpha)
    border.width: 1
    border.color: Theme.alpha(Theme.fg, root.panelOpen
      ? Style.cardActiveBorderAlpha : Style.cardBorderAlpha)

    Behavior on opacity {
      NumberAnimation {
        duration: Style.animFast
      }
    }

    Behavior on color {
      ColorAnimation {
        duration: Style.animFast
      }
    }
  }

  FocusRing {}

  Row {
    id: contentRow
    anchors.centerIn: parent
    spacing: 0
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: root.interactive
    cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (m) => {
      if (m.button === Qt.RightButton)
        root.rightClicked(m)
      else
        root.clicked(m)
    }
    onWheel: (w) => {
      if (w.angleDelta.y > 0)
        root.scrolledUp()
      else if (w.angleDelta.y < 0)
        root.scrolledDown()
    }
  }
}
