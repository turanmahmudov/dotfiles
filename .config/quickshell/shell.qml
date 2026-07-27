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

  // The one panel surface. It exists only while a page is open.
  Loader {
    active: panelController.page.length > 0

    sourceComponent: ShellPanel {
      controller: panelController
    }
  }
}
