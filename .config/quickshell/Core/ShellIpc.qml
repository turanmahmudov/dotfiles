import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Item {
  property var controller: null

  IpcHandler {
    target: "shell"

    function ping(): string {
      return "ok"
    }

    function listPlugins(): string {
      var arr = []
      var plugins = PluginRegistry.listPlugins()
      for (var i = 0; i < plugins.length; i++) {
        var plugin = plugins[i]
        var widgets = []
        for (var name in plugin.widgets)
          widgets.push(name + " (" + plugin.widgets[name].surface + ")")
        arr.push({
          "id": plugin.id,
          "name": plugin.name,
          "placement": plugin.placement,
          "widgets": widgets,
          "page": plugin.page ? plugin.page.mode : "",
          "overlay": !!plugin.overlay
        })
      }
      return JSON.stringify(arr)
    }

    function rescanPlugins(): string {
      PluginRegistry.scan()
      return "ok"
    }

    function reloadConfig(): string {
      ConfigStore.file.reload()
      return "ok"
    }

    function summon(id: string, payload: string): string {
      return controller ? controller.summon(id, payload) : "unknown"
    }

    function hide(id: string): string {
      if (controller)
        controller.hide(id)
      return "ok"
    }

    function toggle(id: string, payload: string): string {
      if (controller)
        controller.toggle(id, payload)
      return "ok"
    }

    // Payload-free variant, so keybinds do not have to pass an empty argument.
    function togglePanel(id: string): string {
      if (controller)
        controller.toggle(id, "")
      return "ok"
    }

    function settings(): string {
      if (controller)
        controller.toggle(controller.settingsPage, "")
      return "ok"
    }
  }
}
