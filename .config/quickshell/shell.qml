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
      return PluginRegistry.listOverlayUrls()
    }

    Loader {
      required property var modelData
      source: modelData
    }
  }

  Variants {
    model: Quickshell.screens

    Bar {
      controller: panelController
    }
  }

  // The one panel surface. It exists while a page is open and until the close animation ends.
  Loader {
    id: panelLoader

    property bool keepAlive: false

    active: panelController.page.length > 0 || panelLoader.keepAlive
    onLoaded: panelLoader.keepAlive = true

    sourceComponent: ShellPanel {
      controller: panelController
      onCloseFinished: panelLoader.keepAlive = false
    }
  }
}
