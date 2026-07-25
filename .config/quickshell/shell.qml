import QtQuick
import Quickshell
import qs.Core
import qs.Services

ShellRoot {
  Component.onCompleted: Hypr.revision

  PanelController {
    id: panelController
  }

  ShellIpc {
    controller: panelController
  }

  Variants {
    model: {
      PluginRegistry.revision
      return PluginRegistry.pluginsOfKind("overlay")
    }

    Loader {
      required property var modelData
      source: PluginRegistry.entryPointUrl(modelData, "overlay")
    }
  }

  Variants {
    model: Quickshell.screens

    Bar {
      controller: panelController
    }
  }
}
