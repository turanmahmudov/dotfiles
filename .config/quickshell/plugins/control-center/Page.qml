import QtQuick
import qs.Commons
import qs.Core
import qs.Services
import qs.Ui

// The home page of the panel. It only arranges what plugins expose on the cc
// surface; the layout decides which widgets appear and in what order.
//
// While editing, the page is also the drag coordinator: a section reports where
// the pointer is, and the page decides which section and which slot it lands in.
// The tray of unplaced widgets rides along as one more section at the end.
PanelPage {
  id: page

  readonly property var layoutModel: LayoutEditor.editing
    ? LayoutEditor.sections.concat([LayoutEditor.traySection])
    : LayoutEditor.sections

  property int dragSection: -1
  property int dragIndex: -1
  property int dropSection: -1
  property int dropIndex: -1

  // Both a drop and a remove rebuild the very sections whose handler is still
  // running, so the change is applied on the next tick.
  property var pendingChange: null

  function beginDrag(sectionIndex, itemIndex) {
    page.dragSection = sectionIndex
    page.dragIndex = itemIndex
    page.dropSection = sectionIndex
    page.dropIndex = itemIndex
  }

  function updateDrag(x, y) {
    var target = page.findSectionAt(y)
    if (!target)
      return
    var local = target.mapFromItem(page, x, y)
    page.dropSection = target.sectionIndex
    page.dropIndex = target.resolveDropIndex(local.x, local.y)
  }

  function endDrag() {
    if (page.dragSection >= 0 && page.dropSection >= 0) {
      page.pendingChange = {
        "kind": "move",
        "from": page.dragSection,
        "fromIndex": page.dragIndex,
        "to": page.dropSection,
        "toIndex": page.dropIndex
      }
      applyTimer.restart()
    }
    page.dragSection = -1
    page.dragIndex = -1
    page.dropSection = -1
    page.dropIndex = -1
  }


  function requestRemove(sectionIndex, itemIndex) {
    page.pendingChange = { "kind": "remove", "from": sectionIndex, "fromIndex": itemIndex }
    applyTimer.restart()
  }

  function applyPendingChange() {
    var change = page.pendingChange
    page.pendingChange = null
    if (!change)
      return
    if (change.kind === "remove")
      LayoutEditor.removeItem(change.from, change.fromIndex)
    else
      LayoutEditor.applyMove(change.from, change.fromIndex, change.to, change.toIndex)
  }

  function findSectionAt(y) {
    var nearest = null
    var nearestDistance = Infinity
    for (var i = 0; i < sectionRepeater.count; i++) {
      var section = sectionRepeater.itemAt(i)
      if (!section || !section.visible)
        continue
      var top = section.mapToItem(page, 0, 0).y
      var bottom = top + section.height
      if (y >= top && y <= bottom)
        return section
      var distance = y < top ? (top - y) : (y - bottom)
      if (distance < nearestDistance) {
        nearestDistance = distance
        nearest = section
      }
    }
    return nearest
  }

  property Timer applyTimer: Timer {
    interval: 0
    onTriggered: page.applyPendingChange()
  }

  Repeater {
    id: sectionRepeater
    model: page.layoutModel

    CcSection {
      required property var modelData
      required property int index
      width: parent.width
      section: modelData
      controller: page.controller
      editing: LayoutEditor.editing
      allowRemove: index !== LayoutEditor.trayIndex
      sectionIndex: index
      coordinator: page
    }
  }

  Item {
    width: parent.width
    height: 18

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      visible: LayoutEditor.editing
      text: "Drag the items, then confirm"
      color: Theme.accent
      font.family: Style.fontFamily
      font.pixelSize: Style.fontMicro
    }

    IconButton {
      id: editButton
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      iconSize: 14
      implicitHeight: parent.height
      tooltipText: LayoutEditor.editing ? "Save the layout" : "Edit the layout"
      name: LayoutEditor.editing ? "check" : "pencil"
      color: LayoutEditor.editing ? Theme.accent : (hovered ? Theme.fg : Theme.fgDim)
      onClicked: LayoutEditor.toggleEditing()
    }

    IconButton {
      anchors.right: editButton.left
      anchors.rightMargin: 2
      anchors.verticalCenter: parent.verticalCenter
      iconSize: 14
      implicitHeight: parent.height
      tooltipText: "Shell settings"
      name: "sliders-horizontal"
      color: hovered ? Theme.fg : Theme.fgDim
      onClicked: if (page.controller) page.controller.go(page.controller.settingsPage)
    }
  }
}
