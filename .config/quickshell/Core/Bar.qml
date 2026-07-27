import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Ui

PanelWindow {
  id: bar
  property var modelData
  property var controller: null
  screen: modelData

  readonly property bool editing: LayoutEditor.editing
  readonly property real rowHeight: Style.barHeight
  readonly property real zoneGap: 8
  readonly property real zoneWidth: (bar.width - 2 * Style.sideMargin - 2 * bar.zoneGap) / 3

  // While editing, the zones keep the screen edge and the tray takes the inner row.
  readonly property real zonesY: (Style.barAtTop || !bar.editing) ? 0 : bar.rowHeight + 4
  readonly property real trayY: Style.barAtTop ? bar.rowHeight + 4 : 0

  anchors {
    top: Style.barAtTop
    bottom: !Style.barAtTop
    left: true
    right: true
  }
  implicitHeight: bar.editing ? bar.rowHeight * 2 + 4 : bar.rowHeight
  color: "transparent"
  WlrLayershell.namespace: "quickshell-bar"
  exclusiveZone: bar.implicitHeight + Style.barMargin

  margins {
    top: Style.barAtTop ? Style.barMargin : 0
    bottom: Style.barAtTop ? 0 : Style.barMargin
    left: Style.barMargin
    right: Style.barMargin
  }

  Rectangle {
    anchors.fill: parent
    visible: Style.barBackgroundAlpha > 0 || bar.editing
    radius: Style.barMargin > 0 ? Style.radius : 0
    // The dotted frames need something to sit on, whatever the wallpaper does.
    color: Theme.alpha(Theme.bg, bar.editing ? 0.85 : Style.barBackgroundAlpha)
  }

  // The zones report the pointer in this item's coordinates, and it decides which
  // zone and which slot a drag lands in.
  Item {
    id: content
    anchors.fill: parent

    property string dragZone: ""
    property int dragIndex: -1
    property string dropZone: ""
    property int dropIndex: -1

    // A drop and a remove both rebuild the zone whose handler is still running, so
    // the change is applied on the next tick.
    property var pendingChange: null

    function beginDrag(zoneName, itemIndex) {
      content.dragZone = zoneName
      content.dragIndex = itemIndex
      content.dropZone = zoneName
      content.dropIndex = itemIndex
    }

    function updateDrag(x, y) {
      var target = content.findZoneAt(x, y)
      if (!target)
        return
      content.dropZone = target.zoneName
      content.dropIndex = target.resolveDropIndex(x - target.x, y - target.y)
    }

    function endDrag() {
      if (content.dragZone.length > 0 && content.dropZone.length > 0) {
        content.pendingChange = {
          "kind": "move",
          "from": content.dragZone,
          "fromIndex": content.dragIndex,
          "to": content.dropZone,
          "toIndex": content.dropIndex
        }
        applyTimer.restart()
      }
      content.dragZone = ""
      content.dragIndex = -1
      content.dropZone = ""
      content.dropIndex = -1
    }


    function requestRemove(zoneName, itemIndex) {
      content.pendingChange = { "kind": "remove", "from": zoneName, "fromIndex": itemIndex }
      applyTimer.restart()
    }

    function applyPendingChange() {
      var change = content.pendingChange
      content.pendingChange = null
      if (!change)
        return
      if (change.kind === "remove")
        LayoutEditor.removeBarItem(change.from, change.fromIndex)
      else
        LayoutEditor.applyBarMove(change.from, change.fromIndex, change.to, change.toIndex)
    }

    function findZoneAt(x, y) {
      var zones = [leftZone, centerZone, rightZone, trayZone]
      var nearest = null
      var nearestDistance = Infinity
      for (var i = 0; i < zones.length; i++) {
        var zone = zones[i]
        if (!zone.visible)
          continue
        if (x >= zone.x && x <= zone.x + zone.width && y >= zone.y && y <= zone.y + zone.height)
          return zone
        var gapX = Math.max(zone.x - x, x - (zone.x + zone.width), 0)
        var gapY = Math.max(zone.y - y, y - (zone.y + zone.height), 0)
        if (gapX + gapY < nearestDistance) {
          nearestDistance = gapX + gapY
          nearest = zone
        }
      }
      return nearest
    }

    Timer {
      id: applyTimer
      interval: 0
      onTriggered: content.applyPendingChange()
    }

    MouseArea {
      anchors.fill: parent
      enabled: !bar.editing
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: if (bar.controller) bar.controller.hideAll()
    }

    BarZone {
      id: leftZone
      zoneName: "left"
      y: bar.zonesY
      x: Style.sideMargin
      width: bar.editing ? bar.zoneWidth : implicitWidth
      entries: LayoutEditor.barZones.left || []
      controller: bar.controller
      hostScreen: bar.modelData
      editing: bar.editing
      coordinator: content
    }

    BarZone {
      id: centerZone
      zoneName: "center"
      y: bar.zonesY
      x: bar.editing
        ? (Style.sideMargin + bar.zoneWidth + bar.zoneGap)
        : ((bar.width - implicitWidth) / 2)
      width: bar.editing ? bar.zoneWidth : implicitWidth
      contentAlignment: Qt.AlignHCenter
      entries: LayoutEditor.barZones.center || []
      controller: bar.controller
      hostScreen: bar.modelData
      editing: bar.editing
      coordinator: content
    }

    BarZone {
      id: rightZone
      zoneName: "right"
      y: bar.zonesY
      x: bar.editing
        ? (Style.sideMargin + 2 * (bar.zoneWidth + bar.zoneGap))
        : (bar.width - Style.sideMargin - implicitWidth)
      width: bar.editing ? bar.zoneWidth : implicitWidth
      contentAlignment: Qt.AlignRight
      entries: LayoutEditor.barZones.right || []
      controller: bar.controller
      hostScreen: bar.modelData
      editing: bar.editing
      coordinator: content
    }

    BarZone {
      id: trayZone
      zoneName: "tray"
      title: "Not shown"
      y: bar.trayY
      x: Style.sideMargin
      width: bar.width - 2 * Style.sideMargin - doneButton.width - styleButton.width - 4 - bar.zoneGap
      visible: bar.editing
      entries: LayoutEditor.barTrayItems
      controller: bar.controller
      hostScreen: bar.modelData
      editing: bar.editing
      allowRemove: false
      coordinator: content
    }

    IconButton {
      id: styleButton
      x: doneButton.x - width - 4
      y: bar.trayY + (bar.rowHeight - height) / 2
      visible: bar.editing
      iconSize: 14
      name: "sliders-horizontal"
      color: hovered ? Theme.fg : Theme.fgDim
      tooltipText: "Shell settings"
      onClicked: if (bar.controller) bar.controller.go(bar.controller.settingsPage)
    }

    IconButton {
      id: doneButton
      x: bar.width - Style.sideMargin - width
      y: bar.trayY + (bar.rowHeight - height) / 2
      visible: bar.editing
      iconSize: 14
      name: "check"
      color: Theme.accent
      tooltipText: "Save the layout"
      onClicked: LayoutEditor.stopEditing()
    }
  }
}
