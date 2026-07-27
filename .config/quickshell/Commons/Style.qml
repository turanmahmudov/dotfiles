pragma Singleton
import QtQuick

QtObject {
  id: root

  property int barHeight: 35
  property int sideMargin: 10
  property int spacing: 7
  property int radius: 10
  property int radiusSmall: 8
  property int paddingH: 6
  property string fontFamily: "JetBrainsMono Nerd Font"
  property int fontSize: 14
  property int iconSize: 15
  property real groupBgAlpha: 0.08
  property int tooltipRadius: 10
  property real surfaceAlpha: 0.9
  property int animFast: 140
  property int anim: 180
  property real barBackgroundAlpha: 0
  property int barMargin: 0

  property int panelWidth: 380
  property int panelPadding: 14
  property int panelSpacing: 10
  property int ccSpacing: 7

  property string barPosition: "top"
  readonly property bool barAtTop: barPosition !== "bottom"

  readonly property var defaults: ({
    "barHeight": 35,
    "sideMargin": 10,
    "spacing": 7,
    "radius": 10,
    "paddingH": 6,
    "fontFamily": "JetBrainsMono Nerd Font",
    "fontSize": 14,
    "iconSize": 15,
    "surfaceAlpha": 0.9,
    "barBackgroundAlpha": 0,
    "barMargin": 0,
    "panelWidth": 380,
    "panelPadding": 14,
    "panelSpacing": 10,
    "ccSpacing": 7
  })

  function applyConfig(style) {
    var s = style || ({})
    root.barHeight = s.barHeight === undefined ? root.defaults.barHeight : s.barHeight
    root.sideMargin = s.sideMargin === undefined ? root.defaults.sideMargin : s.sideMargin
    root.spacing = s.spacing === undefined ? root.defaults.spacing : s.spacing
    root.radius = s.radius === undefined ? root.defaults.radius : s.radius
    root.paddingH = s.paddingH === undefined ? root.defaults.paddingH : s.paddingH
    root.fontFamily = s.fontFamily === undefined ? root.defaults.fontFamily : s.fontFamily
    root.fontSize = s.fontSize === undefined ? root.defaults.fontSize : s.fontSize
    root.iconSize = s.iconSize === undefined ? root.defaults.iconSize : s.iconSize
    root.surfaceAlpha = s.surfaceAlpha === undefined ? root.defaults.surfaceAlpha : s.surfaceAlpha
    root.barBackgroundAlpha = s.barBackgroundAlpha === undefined
      ? root.defaults.barBackgroundAlpha : s.barBackgroundAlpha
    root.barMargin = s.barMargin === undefined ? root.defaults.barMargin : s.barMargin
    root.panelWidth = s.panelWidth === undefined ? root.defaults.panelWidth : s.panelWidth
    root.panelPadding = s.panelPadding === undefined ? root.defaults.panelPadding : s.panelPadding
    root.panelSpacing = s.panelSpacing === undefined ? root.defaults.panelSpacing : s.panelSpacing
    root.ccSpacing = s.ccSpacing === undefined ? root.defaults.ccSpacing : s.ccSpacing
  }
}
