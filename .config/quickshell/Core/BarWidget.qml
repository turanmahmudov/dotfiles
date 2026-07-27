import QtQuick
import qs.Services

Loader {
  id: root

  property var entry: null
  property var controller: null
  property var hostScreen: null

  readonly property string widgetRef: (entry && entry.id) ? String(entry.id) : ""
  readonly property string pluginId: PluginRegistry.parseRef(widgetRef).id

  // Mirrors the widget's own `shown` flag. A host must read this rather than
  // `visible`, which reports the whole parent chain.
  readonly property bool shown: status === Loader.Ready && item !== null && item.shown !== false

  readonly property var mergedSettings: ConfigStore.resolveSettings(root.pluginId, root.entry)

  // Name for a host to show when the widget itself draws nothing.
  readonly property string widgetLabel: {
    PluginRegistry.revision
    var plugin = PluginRegistry.findPlugin(root.pluginId)
    var widget = PluginRegistry.findWidget(root.widgetRef, "bar")
    if (!plugin || !widget)
      return root.widgetRef
    return plugin.name
  }

  active: widgetRef.length > 0
  width: shown ? item.implicitWidth : 0
  height: (status === Loader.Ready && item) ? item.implicitHeight : 0
  visible: width > 0

  source: {
    PluginRegistry.revision
    return widgetRef.length > 0 ? PluginRegistry.resolveWidgetUrl(widgetRef, "bar") : ""
  }

  // Editing a setting must reach a widget already on screen, so this is not a one
  // shot assignment at load.
  onMergedSettingsChanged: {
    if (root.item && "settings" in root.item)
      root.item.settings = root.mergedSettings
  }

  onLoaded: {
    try {
      item.settings = root.mergedSettings
      item.controller = root.controller
      item.screen = root.hostScreen
      if ("pluginId" in item)
        item.pluginId = root.pluginId
    } catch (e) {
      console.warn("BarWidget: failed to wire", widgetRef, e)
    }
  }
}
