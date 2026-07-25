import QtQuick
import qs.Services

Loader {
  id: root

  property var entry: null
  property var controller: null
  property var hostScreen: null

  readonly property string widgetId: (entry && entry.id) ? String(entry.id) : ""

  active: widgetId.length > 0
  width: {
    if (status !== Loader.Ready || !item || item.shown === false)
      return 0
    return item.implicitWidth
  }
  height: (status === Loader.Ready && item) ? item.implicitHeight : 0
  visible: width > 0

  source: {
    PluginRegistry.revision
    return widgetId.length ? PluginRegistry.barWidgetUrl(widgetId) : ""
  }

  onLoaded: {
    try {
      item.settings = entry
      item.controller = root.controller
      item.screen = root.hostScreen
      if ("pluginId" in item)
        item.pluginId = widgetId
    } catch (e) {
      console.warn("BarWidget: failed to wire", widgetId, e)
    }
  }
}
