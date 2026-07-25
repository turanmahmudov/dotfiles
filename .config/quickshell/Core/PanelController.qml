import QtQuick
import Quickshell
import qs.Services

QtObject {
  id: controller

  property var openPanels: ({})

  signal overlaysShouldClose()

  function hidePanels() {
    for (var pid in openPanels)
      hide(pid)
  }

  function hideAll() {
    hidePanels()
    overlaysShouldClose()
  }

  function summonAt(id, anchorItem, payloadJson) {
    var url = PluginRegistry.panelUrl(id)
    if (!url)
      return "unknown"
    controller.overlaysShouldClose()
    var payload = ({})
    try {
      if (payloadJson)
        payload = JSON.parse(payloadJson)
    } catch (e) {
    }
    for (var openId in openPanels) {
      if (openId !== id)
        hide(openId)
    }
    if (openPanels[id]) {
      if (anchorItem)
        openPanels[id].anchorItem = anchorItem
      if (openPanels[id].applyPayload)
        openPanels[id].applyPayload(payload)
      return "ok"
    }
    var comp = Qt.createComponent(url, Component.PreferSynchronous)
    if (comp.status === Component.Error) {
      console.warn("PanelController: error loading", id, comp.errorString())
      return "unknown"
    }
    var win = comp.createObject(null, {
      "controller": controller,
      "anchorItem": anchorItem || null,
      "payload": payload,
      "pluginId": id
    })
    if (!win) {
      console.warn("PanelController: failed to create", id)
      return "unknown"
    }
    var map = openPanels
    map[id] = win
    openPanels = map
    return "ok"
  }

  function toggleAt(id, anchorItem, payloadJson) {
    if (isOpen(id))
      hide(id)
    else
      summonAt(id, anchorItem, payloadJson)
  }

  function summon(id, payloadJson) {
    return summonAt(id, null, payloadJson)
  }

  function toggle(id, payloadJson) {
    if (isOpen(id))
      hide(id)
    else
      summonAt(id, null, payloadJson)
  }

  function hide(id) {
    var w = openPanels[id]
    if (!w)
      return
    w.destroy()
    var map = openPanels
    delete map[id]
    openPanels = map
  }

  function isOpen(id) {
    return !!openPanels[id]
  }
}
