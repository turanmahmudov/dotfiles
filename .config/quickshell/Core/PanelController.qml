import QtQuick
import Quickshell
import qs.Services

// One surface, one current page. There is no map of open windows any more, so
// there is nothing to hide before opening something else, which is what used to
// make a detail view detach from the panel it was opened in.
QtObject {
  id: controller

  readonly property string homePage: "shell.control-center"
  readonly property string settingsPage: "shell.settings"

  // Pages that belong to the shell itself rather than to a plugin. They are not in
  // the registry, so they cannot be placed in a layout or turn up in a tray: the
  // settings of the shell are not a widget.
  readonly property var corePages: ({
    "shell.settings": { "file": "Core/SettingsPage.qml", "mode": "cc" },
    "shell.settings.plugin": { "file": "Core/PluginSettingsPage.qml", "mode": "cc" }
  })

  function resolvePageUrl(id) {
    var core = controller.corePages[id]
    if (core)
      return "file://" + PluginRegistry.configDir + "/" + core.file
    return PluginRegistry.resolvePageUrl(id)
  }

  function resolvePageMode(id) {
    var core = controller.corePages[id]
    if (core)
      return core.mode
    return PluginRegistry.resolvePageMode(id)
  }

  // Empty means the panel is closed.
  property string page: ""
  property Item anchorItem: null
  property var payload: ({})

  // Where the back arrow goes. Without it every page returned to the home page,
  // which sent a plugin's settings back past the settings page it came from.
  property var history: []

  signal overlaysShouldClose()

  function parsePayload(payloadJson) {
    try {
      return payloadJson ? JSON.parse(payloadJson) : ({})
    } catch (e) {
      return ({})
    }
  }

  // A request that arrives before the first plugin scan finishes waits for it. A
  // keybind pressed right after the shell starts used to be dropped instead.
  property string queuedPage: ""
  property Item queuedAnchor: null
  property string queuedPayload: ""

  function openQueued() {
    if (controller.queuedPage.length === 0)
      return
    var id = controller.queuedPage
    var anchor = controller.queuedAnchor
    var payloadJson = controller.queuedPayload
    controller.queuedPage = ""
    controller.queuedAnchor = null
    controller.queuedPayload = ""
    controller.open(id, anchor, payloadJson)
  }

  property Connections registryWatcher: Connections {
    target: PluginRegistry

    function onRevisionChanged() {
      controller.openQueued()
    }
  }

  function open(id, anchor, payloadJson) {
    if (!controller.resolvePageUrl(id)) {
      if (PluginRegistry.revision === 0) {
        controller.queuedPage = id
        controller.queuedAnchor = anchor
        controller.queuedPayload = payloadJson || ""
        return "pending"
      }
      console.warn("PanelController: no page for", id)
      return "unknown"
    }
    controller.overlaysShouldClose()
    if (controller.page.length > 0 && controller.page !== id) {
      var trail = controller.history
      trail.push({ "id": controller.page, "payload": controller.payload })
      controller.history = trail
    }
    controller.payload = parsePayload(payloadJson)
    if (anchor)
      controller.anchorItem = anchor
    controller.page = id
    return "ok"
  }

  // Navigate inside the panel, keeping the surface where the user opened it.
  function go(id) {
    return open(id, null, "")
  }

  function back() {
    if (controller.history.length === 0)
      return open(controller.homePage, null, "")
    var trail = controller.history
    var previous = trail.pop()
    controller.history = trail
    controller.payload = previous.payload
    controller.page = previous.id
    return "ok"
  }

  function close() {
    controller.history = []
    controller.page = ""
  }

  function isOpen(id) {
    return controller.page === id
  }

  function toggleAt(id, anchor, payloadJson) {
    if (controller.page === id)
      controller.close()
    else
      open(id, anchor, payloadJson)
  }

  // Names kept for ShellIpc, the bar and the overlays.
  function summonAt(id, anchor, payloadJson) {
    return open(id, anchor, payloadJson)
  }

  function summon(id, payloadJson) {
    return open(id, null, payloadJson)
  }

  function toggle(id, payloadJson) {
    toggleAt(id, null, payloadJson)
  }

  function hide(id) {
    if (controller.page === id)
      controller.close()
  }

  function hidePanels() {
    controller.close()
  }

  function hideAll() {
    controller.close()
    controller.overlaysShouldClose()
  }
}
