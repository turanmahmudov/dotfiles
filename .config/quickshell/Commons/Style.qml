pragma Singleton
import QtQuick

QtObject {
  readonly property int barHeight: 35
  readonly property int sideMargin: 10
  readonly property int spacing: 7
  readonly property int radius: 10
  readonly property int radiusSmall: 8
  readonly property int paddingH: 6
  readonly property string fontFamily: "JetBrainsMono Nerd Font"
  readonly property int fontSize: 14
  readonly property int iconSize: 15
  readonly property real groupBgAlpha: 0.08
  readonly property int tooltipRadius: 10
  readonly property real surfaceAlpha: 0.9
  readonly property int animFast: 140
  readonly property int anim: 180

  property string barPosition: "top"
  readonly property bool barAtTop: barPosition !== "bottom"
}
