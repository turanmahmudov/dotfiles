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
      var inst = PluginRegistry.installed
      for (var id in inst) {
        var m = inst[id]
        arr.push({
          "id": id,
          "name": m.name,
          "kinds": m.kinds
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
  }
}
