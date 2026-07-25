import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Services

PanelWindow {
  id: popup
  property var controller: null
  property Item anchorItem: null
  property var payload: ({})
  property string pluginId: ""
  property string title: ""
  property int cardWidth: 320
  // Peak height while open. Grows with content, never shrinks — layer-shell
  // surface shrink is what made the whole panel blink.
  property int surfaceHeight: 0
  default property alias content: col.data

  readonly property int contentPadding: 12
  readonly property int innerSpacing: 10

  readonly property var anchorWin: anchorItem ? anchorItem.QsWindow.window : null
  readonly property bool atTop: Style.barAtTop
  readonly property int contentHeight: col.implicitHeight + contentPadding * 2 + 2
  readonly property int maxSurfaceHeight: {
    var h = screen ? screen.height : 0
    if (h <= 0)
      return 10000
    return Math.max(120, h - Style.barHeight - 24)
  }
  readonly property int maxContentHeight: maxSurfaceHeight - contentPadding * 2 - 2

  function applyPayload(p) {
    payload = p || ({})
  }

  function requestClose() {
    if (controller)
      controller.hide(pluginId)
  }

  function reposition() {
    if (!anchorItem || !anchorWin)
      return
    var p = anchorWin.contentItem.mapFromItem(anchorItem, 0, 0)
    var x = p.x + anchorItem.width / 2 - popup.implicitWidth / 2
    x = Math.max(Style.sideMargin, Math.min(x, anchorWin.width - popup.implicitWidth - Style.sideMargin))
    popup.margins.left = Math.round(x)
  }

  function growSurface() {
    var h = Math.min(contentHeight, maxSurfaceHeight)
    if (h > surfaceHeight)
      surfaceHeight = h
  }

  onContentHeightChanged: growSurface()
  onMaxSurfaceHeightChanged: {
    if (surfaceHeight > maxSurfaceHeight)
      surfaceHeight = maxSurfaceHeight
    else
      growSurface()
  }
  Component.onCompleted: {
    surfaceHeight = Math.min(contentHeight, maxSurfaceHeight)
    reposition()
  }

  // Summoned over IPC there is no bar anchor, so fall back to the focused
  // output and let layer-shell centre the surface.
  screen: anchorWin ? anchorWin.screen : Hypr.focusedScreen
  color: "transparent"
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  exclusiveZone: 0
  implicitWidth: cardWidth + 2
  implicitHeight: Math.max(surfaceHeight, 1)

  anchors {
    top: popup.atTop
    bottom: !popup.atTop
    left: popup.anchorItem !== null
  }
  margins.top: popup.atTop ? 8 : 0
  margins.bottom: popup.atTop ? 0 : 8

  onAnchorWinChanged: reposition()

  HyprlandFocusGrab {
    active: popup.visible
    windows: popup.anchorWin ? [popup, popup.anchorWin] : [popup]
    onCleared: popup.requestClose()
  }

  Rectangle {
    id: card
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: popup.atTop ? parent.top : undefined
    anchors.bottom: popup.atTop ? undefined : parent.bottom
    anchors.margins: 1
    height: Math.min(col.implicitHeight + popup.contentPadding * 2, Math.max(0, popup.surfaceHeight - 2))
    radius: Style.radius
    color: Theme.alpha(Theme.bg, Style.surfaceAlpha)
    border.color: Theme.alpha(Theme.fg, 0.15)
    border.width: 1

    Column {
      id: col
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: popup.contentPadding
      spacing: popup.innerSpacing
      width: parent.width - popup.contentPadding * 2

      Text {
        visible: popup.title.length > 0
        width: parent.width
        text: popup.title
        color: Theme.fg
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize + 1
        font.bold: true
      }
    }
  }

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: popup.requestClose()
    Component.onCompleted: forceActiveFocus()
  }
}
