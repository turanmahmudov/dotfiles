import QtQuick
import qs.Commons
import qs.Ui

// One Control Center section. The type picks the arrangement: "grid" puts items
// in equal cells, "stack" gives each item a full width row, and "list" wraps
// rows in one bordered card.
//
// While the layout is edited the section frames itself, names itself, and hands
// its drags to the coordinator. A coordinator answers beginDrag, updateDrag and
// endDrag, and reports dragSection, dragIndex, dropSection and dropIndex.
Item {
  id: root

  property var section: null
  property var controller: null
  property bool editing: false
  property bool allowRemove: true
  property int sectionIndex: 0
  property var coordinator: null

  readonly property string type: (section && section.type) ? String(section.type) : "stack"
  readonly property string title: (section && section.title) ? String(section.title) : ""
  readonly property string hint: (section && section.hint) ? String(section.hint) : ""
  readonly property var items: (section && section.items) ? section.items : []
  readonly property int columns: (section && section.columns > 0) ? Number(section.columns) : 1
  readonly property bool isList: type === "list"
  readonly property bool compact: !!(section && section.compact)
  readonly property real gap: (section && section.spacing !== undefined)
    ? Number(section.spacing)
    : (type === "grid" ? Style.ccSpacing : Style.panelSpacing)

  readonly property int pad: editing ? 8 : 0
  readonly property int headerHeight: (editing && title.length > 0) ? 17 : 0
  readonly property real contentWidth: Math.max(0, width - pad * 2)
  readonly property real cellWidth: type === "grid" ? (contentWidth - gap * (columns - 1)) / columns : contentWidth
  readonly property real bodyHeight: isList ? list.implicitHeight : grid.implicitHeight
  // An emptied section still has to be a drop target while editing.
  readonly property real minBodyHeight: editing ? 42 : 0

  readonly property int dragIndex: (editing && coordinator && coordinator.dragSection === sectionIndex)
    ? coordinator.dragIndex : -1
  readonly property int dropIndex: (editing && coordinator && coordinator.dropSection === sectionIndex)
    ? coordinator.dropIndex : -1
  readonly property var caretRect: dropIndex >= 0 ? resolveCaretRect(dropIndex) : null

  property real dragOffsetX: 0
  property real dragOffsetY: 0
  property real dragOriginX: 0
  property real dragOriginY: 0

  implicitHeight: Math.max(bodyHeight, minBodyHeight) + pad * 2 + headerHeight
  height: implicitHeight
  visible: editing || bodyHeight > 0

  function findSlot(index) {
    var repeater = root.isList ? listRepeater : gridRepeater
    return (index >= 0 && index < repeater.count) ? repeater.itemAt(index) : null
  }

  // Insertion index for a point in section coordinates. A grid decides by the
  // horizontal midpoint of the slots in the row under the point; a single column
  // decides by the vertical midpoint.
  function resolveDropIndex(x, y) {
    var localX = x - root.pad
    var localY = y - root.pad - root.headerHeight
    var count = root.items.length
    var stacked = root.isList || root.columns <= 1
    for (var i = 0; i < count; i++) {
      var slot = root.findSlot(i)
      if (!slot)
        continue
      if (localY > slot.y + slot.height)
        continue
      if (stacked)
        return localY < slot.y + slot.height / 2 ? i : i + 1
      if (localX < slot.x + slot.width / 2)
        return i
    }
    return count
  }

  function resolveCaretRect(index) {
    var thickness = 2
    var count = root.items.length
    if (count === 0)
      return { "x": 0, "y": 0, "width": root.contentWidth, "height": thickness }
    var sideways = !root.isList && root.columns > 1
    var append = index >= count
    var edge = root.findSlot(append ? count - 1 : index)
    if (!edge)
      return null
    if (sideways) {
      var edgeX = append ? (edge.x + edge.width + root.gap / 2) : (edge.x - root.gap / 2)
      return { "x": edgeX - thickness / 2, "y": edge.y, "width": thickness, "height": edge.height }
    }
    var edgeY = append ? (edge.y + edge.height + root.gap / 2) : (edge.y - root.gap / 2)
    return { "x": 0, "y": edgeY - thickness / 2, "width": root.contentWidth, "height": thickness }
  }

  function beginDrag(slot, index, mouse) {
    if (!root.coordinator)
      return
    var start = slot.mapToItem(root.coordinator, mouse.x, mouse.y)
    root.dragOriginX = start.x
    root.dragOriginY = start.y
    root.dragOffsetX = 0
    root.dragOffsetY = 0
    root.coordinator.beginDrag(root.sectionIndex, index)
  }

  // The slot carries the drag offset, so the pointer is read in the coordinator's
  // coordinates: a position read inside the slot would move with the slot itself.
  function updateDrag(slot, mouse) {
    if (!root.coordinator || root.dragIndex < 0)
      return
    var at = slot.mapToItem(root.coordinator, mouse.x, mouse.y)
    root.dragOffsetX = at.x - root.dragOriginX
    root.dragOffsetY = at.y - root.dragOriginY
    root.coordinator.updateDrag(at.x, at.y)
  }

  function endDrag() {
    root.dragOffsetX = 0
    root.dragOffsetY = 0
    if (root.coordinator)
      root.coordinator.endDrag()
  }

  function requestRemove(index) {
    if (root.coordinator)
      root.coordinator.requestRemove(root.sectionIndex, index)
  }


  component Slot: Item {
    id: slot
    required property var modelData
    required property int index

    readonly property bool dragging: root.dragIndex === slot.index
    // A widget that draws nothing right now still has to be movable, so it keeps a
    // named placeholder while the layout is edited.
    readonly property bool placeholder: root.editing && !loader.shown

    height: slot.placeholder ? 34 : loader.height
    visible: loader.shown || root.editing
    z: slot.dragging ? 10 : 0
    opacity: slot.dragging ? 0.85 : 1

    transform: Translate {
      x: slot.dragging ? root.dragOffsetX : 0
      y: slot.dragging ? root.dragOffsetY : 0
    }

    CcWidget {
      id: loader
      width: slot.width
      entry: slot.modelData
      controller: root.controller
      compact: root.compact
      // Only a list wants separators and shared corners between its rows.
      itemIndex: root.isList ? slot.index : 0
      itemCount: root.isList ? root.items.length : 1
    }

    Rectangle {
      anchors.fill: parent
      visible: slot.placeholder
      radius: Style.radiusSmall
      color: Theme.alpha(Theme.fg, 0.03)
      border.width: 1
      border.color: Theme.alpha(Theme.fg, 0.15)

      Text {
        anchors.fill: parent
        anchors.margins: 5
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: loader.widgetLabel
        color: Theme.fgDim
        font.family: Style.fontFamily
        font.pixelSize: Style.fontMicro
      }
    }

    MouseArea {
      anchors.fill: parent
      enabled: root.editing
      visible: root.editing
      preventStealing: true
      cursorShape: slot.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
      onPressed: (mouse) => root.beginDrag(slot, slot.index, mouse)
      onPositionChanged: (mouse) => root.updateDrag(slot, mouse)
      onReleased: root.endDrag()
      onCanceled: root.endDrag()
    }

    // Declared after the drag handler, so the corner takes the click.
    Rectangle {
      id: removeBadge
      z: 30
      anchors.right: parent.right
      anchors.top: parent.top
      // Sits on the corner rather than over it, to keep the arrow zone of a big
      // tile readable.
      anchors.margins: -5
      width: 16
      height: 16
      radius: 8
      visible: root.editing && root.allowRemove && !slot.dragging
      color: removeArea.containsMouse ? Theme.error : Theme.alpha(Theme.bg, 0.85)
      border.width: 1
      border.color: removeArea.containsMouse ? Theme.error : Theme.alpha(Theme.fg, 0.3)

      Icon {
        anchors.centerIn: parent
        size: 10
        name: "x"
        color: removeArea.containsMouse ? Theme.bg : Theme.fgDim
      }

      MouseArea {
        id: removeArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.requestRemove(slot.index)
      }
    }

  }

  DashedFrame {
    anchors.fill: parent
    visible: root.editing
    color: root.dropIndex >= 0 ? Theme.accent : Theme.alpha(Theme.fg, 0.3)
  }

  Text {
    x: root.pad
    y: 3
    visible: root.headerHeight > 0
    text: root.title
    color: root.dropIndex >= 0 ? Theme.accent : Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontMicro
  }

  Item {
    id: body
    x: root.pad
    y: root.pad + root.headerHeight
    width: root.contentWidth
    height: Math.max(root.bodyHeight, root.minBodyHeight)

    Grid {
      id: grid
      width: body.width
      columns: root.type === "grid" ? root.columns : 1
      columnSpacing: root.gap
      rowSpacing: root.gap

      Repeater {
        id: gridRepeater
        model: root.isList ? [] : root.items

        Slot {
          width: root.cellWidth
        }
      }
    }

    InfoList {
      id: list
      visible: root.isList

      Repeater {
        id: listRepeater
        model: root.isList ? root.items : []

        Slot {
          width: parent ? parent.width : 0
        }
      }
    }

    Text {
      anchors.centerIn: parent
      visible: root.editing && root.items.length === 0 && root.hint.length > 0
      text: root.hint
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontMicro
    }

    Rectangle {
      z: 20
      visible: !!root.caretRect
      x: root.caretRect ? root.caretRect.x : 0
      y: root.caretRect ? root.caretRect.y : 0
      width: root.caretRect ? root.caretRect.width : 0
      height: root.caretRect ? root.caretRect.height : 0
      radius: 1
      color: Theme.accent
    }
  }
}
