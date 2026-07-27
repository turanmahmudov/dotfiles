import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Services
import qs.Ui

// The shell's only panel surface. It hosts one page at a time. Keeping the
// namespace as "quickshell-popup" means the existing Hyprland layerrule (blur,
// no_anim) still applies, and no_anim is what makes shrinking between pages safe.
PanelWindow {
  id: panel

  property var controller: null

  readonly property string pageId: controller ? controller.page : ""
  readonly property bool onHome: controller ? (pageId === controller.homePage) : false
  readonly property Item anchorItem: controller ? controller.anchorItem : null
  readonly property var anchorWin: anchorItem ? anchorItem.QsWindow.window : null
  readonly property bool atTop: Style.barAtTop

  readonly property int maxHeight: {
    var h = screen ? screen.height : 0
    if (h <= 0)
      return 900
    return Math.max(160, h - Style.barHeight - 24)
  }
  readonly property int wantHeight: Math.min(header.height + body.contentHeight, maxHeight)

  readonly property bool standalone: !!controller && controller.resolvePageMode(pageId) === "standalone"
  // A page with no title and nothing to put beside it gets no header at all.
  readonly property bool showHeader: !!(pageLoader.item && pageLoader.item.title.length > 0)
    || backButton.visible || headerSwitch.visible
  readonly property bool followsAnchor: standalone && anchorItem !== null

  function repositionUnderAnchor() {
    if (!followsAnchor || !anchorWin)
      return
    var p = anchorWin.contentItem.mapFromItem(anchorItem, 0, 0)
    var x = p.x + anchorItem.width / 2 - panel.implicitWidth / 2
    x = Math.max(Style.sideMargin, Math.min(x, anchorWin.width - panel.implicitWidth - Style.sideMargin))
    panel.margins.left = Math.round(x)
  }

  // The anchor always decides which monitor the panel belongs to and keeps the
  // bar inside the focus grab. It only decides the position for standalone
  // pages; Control Center and its pages share one corner so the surface does
  // not move as you navigate between them.
  screen: anchorWin ? anchorWin.screen : Hypr.focusedScreen
  color: "transparent"
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  exclusiveZone: 0
  implicitWidth: Style.panelWidth + 2
  implicitHeight: Math.max(wantHeight, 1)

  anchors {
    top: panel.atTop
    bottom: !panel.atTop
    left: panel.followsAnchor
    right: !panel.followsAnchor
  }
  margins.top: panel.atTop ? 8 : 0
  margins.bottom: panel.atTop ? 0 : 8
  margins.right: Style.sideMargin

  onFollowsAnchorChanged: repositionUnderAnchor()
  onAnchorWinChanged: repositionUnderAnchor()

  HyprlandFocusGrab {
    active: panel.visible
    windows: panel.anchorWin ? [panel, panel.anchorWin] : [panel]
    onCleared: if (panel.controller) panel.controller.close()
  }

  Rectangle {
    id: card
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: panel.atTop ? parent.top : undefined
    anchors.bottom: panel.atTop ? undefined : parent.bottom
    anchors.margins: 1
    height: Math.max(0, panel.wantHeight - 2)
    radius: Style.radius
    color: Theme.alpha(Theme.bg, Style.surfaceAlpha)
    border.color: Theme.alpha(Theme.fg, 0.15)
    border.width: 1

    Item {
      id: header
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: panel.showHeader ? 54 : 0
      visible: panel.showHeader

      Rectangle {
        id: backButton
        anchors.left: parent.left
        anchors.leftMargin: Style.panelPadding
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        height: 30
        radius: Style.radiusSmall
        visible: !panel.onHome && !panel.standalone
        color: Theme.alpha(Theme.fg, backArea.containsMouse ? 0.14 : 0.04)
        border.width: 1
        border.color: Theme.alpha(Theme.fg, 0.12)

        Icon {
          anchors.centerIn: parent
          name: "chevron-left"
          color: backArea.containsMouse ? Theme.fg : Theme.fgDim
        }

        MouseArea {
          id: backArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: if (panel.controller) panel.controller.back()
        }
      }

      Switch {
        id: headerSwitch
        anchors.right: parent.right
        anchors.rightMargin: Style.panelPadding
        anchors.verticalCenter: parent.verticalCenter
        visible: !panel.onHome && pageLoader.item && pageLoader.item.hasSwitch === true
        checked: visible ? pageLoader.item.switchOn : false
        onToggled: if (pageLoader.item) pageLoader.item.switchToggled()
      }

      Text {
        anchors.left: backButton.visible ? backButton.right : parent.left
        anchors.leftMargin: backButton.visible ? 10 : Style.panelPadding
        anchors.right: headerSwitch.visible ? headerSwitch.left : parent.right
        anchors.rightMargin: headerSwitch.visible ? 10 : Style.panelPadding
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: pageLoader.item ? pageLoader.item.title : ""
        color: Theme.fgBright
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize
        font.bold: true
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        visible: !panel.onHome
        color: Theme.alpha(Theme.fg, 0.1)
      }
    }

    Flickable {
      id: body
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: header.bottom
      anchors.bottom: parent.bottom
      clip: true
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds
      contentWidth: width
      contentHeight: pageLoader.implicitHeight + Style.panelPadding * 2

      Loader {
        id: pageLoader
        x: Style.panelPadding
        y: Style.panelPadding
        width: body.width - Style.panelPadding * 2

        readonly property string pageUrl: {
          PluginRegistry.revision
          if (panel.pageId.length === 0 || !panel.controller)
            return ""
          return panel.controller.resolvePageUrl(panel.pageId)
        }

        // The page receives its host properties as initial values. Assigning them
        // after the load is too late for everything the page builds while it is
        // constructed, such as the Control Center sections.
        function loadPage() {
          if (String(pageLoader.source) === pageLoader.pageUrl)
            return
          if (pageLoader.pageUrl.length === 0) {
            pageLoader.setSource("")
            return
          }
          pageLoader.setSource(pageLoader.pageUrl, {
            "controller": panel.controller,
            "anchorItem": panel.anchorItem,
            "payload": panel.controller ? panel.controller.payload : ({}),
            "pluginId": panel.pageId
          })
        }

        onPageUrlChanged: loadPage()
        Component.onCompleted: loadPage()

        // A page can be summoned again with a different payload while it is already
        // showing, which changes no url and so reloads nothing. The settings form is
        // one page for every widget, so it has to follow the payload.
        Connections {
          target: panel.controller

          function onPayloadChanged() {
            if (pageLoader.item && "payload" in pageLoader.item)
              pageLoader.item.payload = panel.controller.payload
          }
        }
      }
    }
  }

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: if (panel.controller) panel.controller.close()
    Component.onCompleted: forceActiveFocus()
  }
}
