pragma Singleton
import QtQuick

// Working copy of both layouts. The bar and the Control Center render this rather
// than the config directly, so a drag can rearrange them before they are written
// back. One editing flag covers both surfaces.
//
// Each surface has a tray of the widgets its layout leaves out. Dragging out of a
// tray adds a widget and dragging into it removes one, so both directions are the
// same gesture. A tray is derived, never stored.
QtObject {
  id: root

  property bool editing: false

  property var sections: []
  property var barZones: ({ "left": [], "center": [], "right": [] })

  readonly property var barZoneNames: ["left", "center", "right"]

  readonly property int trayIndex: root.sections.length
  readonly property var trayItems: {
    PluginRegistry.revision
    return root.collectUnplaced("cc")
  }
  // One item per row. A slider or a list row has fixed chrome that needs the full
  // width, and a grid cell leaves it with no room for its own label.
  readonly property var traySection: ({
    "title": "Not shown",
    "hint": "Drag an item here to remove it",
    "type": "stack",
    "spacing": 7,
    "compact": true,
    "items": root.trayItems
  })

  readonly property var barTrayItems: {
    PluginRegistry.revision
    return root.collectUnplaced("bar")
  }

  function copyValue(source) {
    return JSON.parse(JSON.stringify(source || []))
  }

  function syncFromConfig() {
    var incomingSections = ConfigStore.ccSections
    // The shell reloads its own writes, and rebuilding for a layout that already
    // matches would throw away no work but flicker the surface.
    if (JSON.stringify(incomingSections) !== JSON.stringify(root.sections))
      root.sections = root.copyValue(incomingSections)
    var incomingZones = {
      "left": ConfigStore.leftWidgets,
      "center": ConfigStore.centerWidgets,
      "right": ConfigStore.rightWidgets
    }
    if (JSON.stringify(incomingZones) !== JSON.stringify(root.barZones))
      root.barZones = root.copyValue(incomingZones)
  }

  // No read of the config here. The watcher below keeps the working copies current
  // while nothing is being edited, and re-reading would lose the last change
  // whenever a save is still on its way back through the file watch.
  function startEditing() {
    root.editing = true
  }

  function stopEditing() {
    root.saveNow()
    root.editing = false
  }

  function toggleEditing() {
    if (root.editing)
      root.stopEditing()
    else
      root.startEditing()
  }

  function saveNow() {
    saveTimer.stop()
    ConfigStore.saveLayouts(root.barZones, root.sections)
  }

  // Keyed by plugin and widget name, so a bare reference and a named one for the
  // same widget count as the same placement.
  function markPlaced(placed, entries, surface) {
    for (var i = 0; i < entries.length; i++) {
      var entry = entries[i]
      if (entry && entry.group !== undefined) {
        root.markPlaced(placed, entry.group || [], surface)
        continue
      }
      var ref = String((entry && entry.id) || "")
      var widget = PluginRegistry.findWidget(ref, surface)
      placed[widget ? (PluginRegistry.parseRef(ref).id + ":" + widget.name) : ref] = true
    }
  }

  function collectUnplaced(surface) {
    var placed = ({})
    if (surface === "cc") {
      for (var s = 0; s < root.sections.length; s++)
        root.markPlaced(placed, root.sections[s].items || [], surface)
    } else {
      for (var z = 0; z < root.barZoneNames.length; z++)
        root.markPlaced(placed, root.barZones[root.barZoneNames[z]] || [], surface)
    }
    var out = []
    var installed = PluginRegistry.installed
    for (var id in installed) {
      var widgets = installed[id].widgets
      for (var name in widgets) {
        if (widgets[name].surface !== surface)
          continue
        var key = id + ":" + name
        if (!placed[key])
          out.push({ "id": key })
      }
    }
    return out
  }

  function addItem(ref, sectionIndex, itemIndex) {
    var next = root.copyValue(root.sections)
    if (!next[sectionIndex])
      return
    var items = next[sectionIndex].items || []
    items.splice(Math.max(0, Math.min(itemIndex, items.length)), 0, { "id": ref })
    next[sectionIndex].items = items
    root.sections = next
    saveTimer.restart()
  }

  function removeItem(sectionIndex, itemIndex) {
    var next = root.copyValue(root.sections)
    if (!next[sectionIndex])
      return
    var items = next[sectionIndex].items || []
    if (itemIndex < 0 || itemIndex >= items.length)
      return
    items.splice(itemIndex, 1)
    next[sectionIndex].items = items
    root.sections = next
    saveTimer.restart()
  }

  function moveItem(fromSection, fromIndex, toSection, toIndex) {
    var next = root.copyValue(root.sections)
    if (!next[fromSection] || !next[toSection])
      return
    var fromItems = next[fromSection].items || []
    var moved = fromItems.splice(fromIndex, 1)[0]
    if (!moved)
      return
    var toItems = (fromSection === toSection) ? fromItems : (next[toSection].items || [])
    var at = (fromSection === toSection && toIndex > fromIndex) ? toIndex - 1 : toIndex
    at = Math.max(0, Math.min(at, toItems.length))
    toItems.splice(at, 0, moved)
    next[fromSection].items = fromItems
    next[toSection].items = toItems
    root.sections = next
    saveTimer.restart()
  }

  function applyMove(fromSection, fromIndex, toSection, toIndex) {
    if (fromSection === root.trayIndex && toSection === root.trayIndex)
      return
    if (fromSection === root.trayIndex) {
      var item = root.trayItems[fromIndex]
      if (item)
        root.addItem(item.id, toSection, toIndex)
      return
    }
    if (toSection === root.trayIndex) {
      root.removeItem(fromSection, fromIndex)
      return
    }
    root.moveItem(fromSection, fromIndex, toSection, toIndex)
  }

  function findBarEntries(zone) {
    if (zone === "tray")
      return root.barTrayItems
    return root.barZones[zone] || []
  }

  function addBarItem(ref, zone, index) {
    var next = root.copyValue(root.barZones)
    var entries = next[zone] || []
    entries.splice(Math.max(0, Math.min(index, entries.length)), 0, { "id": ref })
    next[zone] = entries
    root.barZones = next
    saveTimer.restart()
  }

  function removeBarItem(zone, index) {
    var next = root.copyValue(root.barZones)
    var entries = next[zone] || []
    if (index < 0 || index >= entries.length)
      return
    entries.splice(index, 1)
    next[zone] = entries
    root.barZones = next
    saveTimer.restart()
  }

  function moveBarItem(fromZone, fromIndex, toZone, toIndex) {
    var next = root.copyValue(root.barZones)
    var fromEntries = next[fromZone] || []
    var moved = fromEntries.splice(fromIndex, 1)[0]
    if (!moved)
      return
    var toEntries = (fromZone === toZone) ? fromEntries : (next[toZone] || [])
    var at = (fromZone === toZone && toIndex > fromIndex) ? toIndex - 1 : toIndex
    at = Math.max(0, Math.min(at, toEntries.length))
    toEntries.splice(at, 0, moved)
    next[fromZone] = fromEntries
    next[toZone] = toEntries
    root.barZones = next
    saveTimer.restart()
  }

  function applyBarMove(fromZone, fromIndex, toZone, toIndex) {
    if (fromZone === "tray" && toZone === "tray")
      return
    if (fromZone === "tray") {
      var item = root.barTrayItems[fromIndex]
      if (item)
        root.addBarItem(item.id, toZone, toIndex)
      return
    }
    if (toZone === "tray") {
      root.removeBarItem(fromZone, fromIndex)
      return
    }
    root.moveBarItem(fromZone, fromIndex, toZone, toIndex)
  }

  property Timer saveTimer: Timer {
    interval: 400
    onTriggered: ConfigStore.saveLayouts(root.barZones, root.sections)
  }

  // The shell writes the layouts itself, so a reload of its own file must not
  // throw away an edit in progress.
  property Connections configWatcher: Connections {
    target: ConfigStore

    function onConfigChanged() {
      if (!root.editing)
        root.syncFromConfig()
    }
  }

  Component.onCompleted: root.syncFromConfig()
}
