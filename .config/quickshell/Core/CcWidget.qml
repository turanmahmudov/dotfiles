import QtQuick
import qs.Services

// Hosts one Control Center widget. The section owns the width, the widget owns
// its height, and a widget that sets `shown` to false collapses its cell.
Loader {
  id: root

  property var entry: null
  property var controller: null
  property bool compact: false
  property int itemIndex: 0
  property int itemCount: 1

  readonly property string widgetRef: (entry && entry.id) ? String(entry.id) : ""
  readonly property string pluginId: PluginRegistry.parseRef(widgetRef).id

  readonly property var mergedSettings: ConfigStore.resolveSettings(root.pluginId, root.entry)

  // Name for a host to show when the widget itself draws nothing.
  readonly property string widgetLabel: {
    PluginRegistry.revision
    var plugin = PluginRegistry.findPlugin(root.pluginId)
    var widget = PluginRegistry.findWidget(root.widgetRef, "cc")
    if (!plugin || !widget)
      return root.widgetRef
    return plugin.name + " " + widget.name
  }

  // Mirrors the widget's own `shown` flag. A host must read this rather than
  // `visible`, which reports the whole parent chain and latches to false if a
  // parent sizes itself from it.
  readonly property bool shown: status === Loader.Ready && item !== null && item.shown !== false

  active: widgetRef.length > 0
  height: shown ? item.implicitHeight : 0
  visible: shown

  source: {
    PluginRegistry.revision
    return widgetRef.length > 0 ? PluginRegistry.resolveWidgetUrl(widgetRef, "cc") : ""
  }

  function assignIfDeclared(name, value) {
    if (item && name in item)
      item[name] = value
  }

  // Editing a setting must reach a widget already on screen, so this is not a one
  // shot assignment at load.
  onMergedSettingsChanged: assignIfDeclared("settings", root.mergedSettings)

  onLoaded: {
    assignIfDeclared("settings", root.mergedSettings)
    assignIfDeclared("controller", root.controller)
    assignIfDeclared("pluginId", root.pluginId)
    assignIfDeclared("compact", root.compact)
    // A row inside a list draws its own separator and corners, so the host tells
    // it where it sits instead of the row inspecting its siblings.
    assignIfDeclared("isFirst", root.itemIndex === 0)
    assignIfDeclared("isLast", root.itemIndex === root.itemCount - 1)
  }
}
