import QtQuick
import qs.Commons
import qs.Ui

// One bar zone: left, center, right, or the tray of widgets the bar leaves out.
// Normally it is a plain row that sizes to its content. While the layout is edited
// it frames itself and hands its drags to the coordinator, which is any object that
// answers beginDrag, updateDrag, endDrag and requestRemove, and reports dragZone,
// dragIndex, dropZone and dropIndex.
//
// A group entry moves as one piece. Its members are not dragged separately.
Item {
  id: zone

  property string zoneName: ""
  property string title: ""
  property var entries: []
  property var controller: null
  property var hostScreen: null
  property bool editing: false
  property bool allowRemove: true
  property var coordinator: null

  property int contentAlignment: Qt.AlignLeft

  readonly property int pad: editing ? 6 : 0
  readonly property real titleWidth: (editing && title.length > 0) ? zoneTitle.implicitWidth + 8 : 0

  // Normally a zone is only as wide as its content, so the content starts at the
  // left edge. While editing the zones share the width equally, and each one holds
  // its content where the bar itself would put it.
  readonly property real rowX: {
    var start = zone.pad + zone.titleWidth
    if (!zone.editing)
      return start
    if (zone.contentAlignment === Qt.AlignHCenter)
      return Math.max(start, (zone.width - row.width) / 2)
    if (zone.contentAlignment === Qt.AlignRight)
      return Math.max(start, zone.width - zone.pad - row.width)
    return start
  }

  readonly property int dragIndex: (editing && coordinator && coordinator.dragZone === zoneName)
    ? coordinator.dragIndex : -1
  readonly property int dropIndex: (editing && coordinator && coordinator.dropZone === zoneName)
    ? coordinator.dropIndex : -1
  readonly property var caretRect: dropIndex >= 0 ? resolveCaretRect(dropIndex) : null

  property real dragOffsetX: 0
  property real dragOffsetY: 0
  property real dragOriginX: 0
  property real dragOriginY: 0

  implicitWidth: row.implicitWidth + pad * 2 + titleWidth
  height: Style.barHeight

  function findSlot(index) {
    return (index >= 0 && index < slots.count) ? slots.itemAt(index) : null
  }

  // Insertion index for a point in zone coordinates. A zone is one row, so only
  // the horizontal midpoints of its slots matter.
  function resolveDropIndex(x, y) {
    var localX = x - row.x
    for (var i = 0; i < zone.entries.length; i++) {
      var slot = zone.findSlot(i)
      if (!slot)
        continue
      if (localX < slot.x + slot.width / 2)
        return i
    }
    return zone.entries.length
  }

  function resolveCaretRect(index) {
    var thickness = 2
    var count = zone.entries.length
    if (count === 0)
      return { "x": row.x, "y": 5, "width": thickness, "height": Style.barHeight - 10 }
    var append = index >= count
    var edge = zone.findSlot(append ? count - 1 : index)
    if (!edge)
      return null
    var edgeX = append
      ? (edge.x + edge.width + Style.spacing / 2)
      : (edge.x - Style.spacing / 2)
    return {
      "x": row.x + edgeX - thickness / 2,
      "y": 5,
      "width": thickness,
      "height": Style.barHeight - 10
    }
  }

  function beginDrag(slot, index, mouse) {
    if (!zone.coordinator)
      return
    var start = slot.mapToItem(zone.coordinator, mouse.x, mouse.y)
    zone.dragOriginX = start.x
    zone.dragOriginY = start.y
    zone.dragOffsetX = 0
    zone.dragOffsetY = 0
    zone.coordinator.beginDrag(zone.zoneName, index)
  }

  // The slot carries the drag offset, so the pointer is read in the coordinator's
  // coordinates: a position read inside the slot would move with the slot itself.
  function updateDrag(slot, mouse) {
    if (!zone.coordinator || zone.dragIndex < 0)
      return
    var at = slot.mapToItem(zone.coordinator, mouse.x, mouse.y)
    zone.dragOffsetX = at.x - zone.dragOriginX
    zone.dragOffsetY = at.y - zone.dragOriginY
    zone.coordinator.updateDrag(at.x, at.y)
  }

  function endDrag() {
    zone.dragOffsetX = 0
    zone.dragOffsetY = 0
    if (zone.coordinator)
      zone.coordinator.endDrag()
  }

  function requestRemove(index) {
    if (zone.coordinator)
      zone.coordinator.requestRemove(zone.zoneName, index)
  }


  // One layout entry: either a widget {id} or a group {group:[...]}.
  // Size slots from child.width (Loader), never child.implicitWidth (always 0 on Loader).
  component Slot: Item {
    id: slot
    required property var modelData
    required property int index

    readonly property bool isGroup: !!(modelData && modelData.group !== undefined)
    readonly property bool contentShown: slot.isGroup || widget.shown
    // A widget that draws nothing right now still has to be movable, so it keeps a
    // named chip while the layout is edited.
    readonly property bool placeholder: zone.editing && !slot.contentShown
    readonly property bool dragging: zone.dragIndex === slot.index

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    width: slot.placeholder ? chip.width : (slot.isGroup ? group.width : widget.width)
    height: Style.barHeight
    visible: slot.contentShown || zone.editing
    z: slot.dragging ? 10 : 0
    opacity: slot.dragging ? 0.85 : 1

    transform: Translate {
      x: slot.dragging ? zone.dragOffsetX : 0
      y: slot.dragging ? zone.dragOffsetY : 0
    }

    BarWidget {
      id: widget
      anchors.verticalCenter: parent.verticalCenter
      entry: slot.isGroup ? null : slot.modelData
      controller: zone.controller
      hostScreen: zone.hostScreen
      visible: !slot.isGroup && !slot.placeholder
      active: !slot.isGroup && !!(slot.modelData && slot.modelData.id)
    }

    BarGroup {
      id: group
      anchors.verticalCenter: parent.verticalCenter
      entries: slot.isGroup ? (slot.modelData.group || []) : []
      controller: zone.controller
      hostScreen: zone.hostScreen
      visible: slot.isGroup && !slot.placeholder
    }

    Rectangle {
      id: chip
      anchors.verticalCenter: parent.verticalCenter
      width: chipLabel.implicitWidth + 14
      height: Style.barHeight - 12
      radius: Style.radiusSmall
      visible: slot.placeholder
      color: Theme.alpha(Theme.fg, 0.03)
      border.width: 1
      border.color: Theme.alpha(Theme.fg, 0.15)

      Text {
        id: chipLabel
        anchors.centerIn: parent
        text: widget.widgetLabel
        color: Theme.fgDim
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize - 5
      }
    }

    MouseArea {
      anchors.fill: parent
      enabled: zone.editing
      visible: zone.editing
      preventStealing: true
      cursorShape: slot.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
      onPressed: (mouse) => zone.beginDrag(slot, slot.index, mouse)
      onPositionChanged: (mouse) => zone.updateDrag(slot, mouse)
      onReleased: zone.endDrag()
      onCanceled: zone.endDrag()
    }

    // Declared after the drag handler, so the corner takes the click.
    Rectangle {
      z: 30
      anchors.right: parent.right
      anchors.top: parent.top
      width: 13
      height: 13
      radius: 7
      visible: zone.editing && zone.allowRemove && !slot.dragging
      color: removeArea.containsMouse ? Theme.error : Theme.alpha(Theme.bg, 0.9)
      border.width: 1
      border.color: removeArea.containsMouse ? Theme.error : Theme.alpha(Theme.fg, 0.35)

      Icon {
        anchors.centerIn: parent
        size: 9
        name: "x"
        color: removeArea.containsMouse ? Theme.bg : Theme.fgDim
      }

      MouseArea {
        id: removeArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: zone.requestRemove(slot.index)
      }
    }

  }

  DashedFrame {
    anchors.fill: parent
    visible: zone.editing
    color: zone.dropIndex >= 0 ? Theme.accent : Theme.alpha(Theme.fg, 0.3)
  }

  Text {
    id: zoneTitle
    x: zone.pad
    anchors.verticalCenter: parent.verticalCenter
    visible: zone.titleWidth > 0
    text: zone.title
    color: zone.dropIndex >= 0 ? Theme.accent : Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize - 5
  }

  Row {
    id: row
    x: zone.rowX
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spacing

    Repeater {
      id: slots
      model: zone.entries

      Slot {}
    }
  }

  Rectangle {
    z: 20
    visible: !!zone.caretRect
    x: zone.caretRect ? zone.caretRect.x : 0
    y: zone.caretRect ? zone.caretRect.y : 0
    width: zone.caretRect ? zone.caretRect.width : 0
    height: zone.caretRect ? zone.caretRect.height : 0
    radius: 1
    color: Theme.accent
  }
}
