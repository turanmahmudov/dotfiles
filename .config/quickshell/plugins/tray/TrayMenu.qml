import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons

PanelWindow {
  id: menu
  property var trayItem: null
  property Item anchorItem: null

  readonly property var anchorWin: anchorItem ? anchorItem.QsWindow.window : null
  readonly property bool atTop: Style.barAtTop

  function openAt(item, anchor) {
    menu.trayItem = item
    menu.anchorItem = anchor
    menu.visible = true
    reposition()
    keyScope.forceActiveFocus()
  }

  function close() {
    menu.visible = false
    menu.trayItem = null
  }

  function reposition() {
    if (!anchorItem || !anchorWin)
      return
    var p = anchorWin.contentItem.mapFromItem(anchorItem, 0, 0)
    var x = p.x + anchorItem.width / 2 - menu.implicitWidth / 2
    x = Math.max(Style.sideMargin, Math.min(x, anchorWin.width - menu.implicitWidth - Style.sideMargin))
    menu.margins.left = Math.round(x)
  }

  visible: false
  screen: anchorWin ? anchorWin.screen : null
  color: "transparent"
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  exclusiveZone: 0
  implicitWidth: 240
  implicitHeight: card.implicitHeight

  anchors {
    top: menu.atTop
    bottom: !menu.atTop
    left: true
  }
  margins.top: menu.atTop ? 8 : 0
  margins.bottom: menu.atTop ? 0 : 8

  onVisibleChanged: if (visible) reposition()

  HyprlandFocusGrab {
    active: menu.visible
    windows: menu.anchorWin ? [menu, menu.anchorWin] : [menu]
    onCleared: menu.close()
  }

  Rectangle {
    id: card
    anchors.fill: parent
    implicitHeight: listCol.implicitHeight + 8
    radius: Style.radiusSmall
    color: Theme.alpha(Theme.bg, Style.surfaceAlpha)
    border.color: Theme.alpha(Theme.fg, Style.surfaceBorderAlpha)
    border.width: 1

    TrayMenuList {
      id: listCol
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 4
      menuHandle: menu.trayItem ? menu.trayItem.menu : null
      onRequestClose: menu.close()
    }
  }

  Item {
    id: keyScope
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: menu.close()
  }
}
