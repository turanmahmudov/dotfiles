import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Ui

PanelWindow {
  id: picker

  screen: Hypr.focusedScreen
  color: "transparent"
  WlrLayershell.namespace: "quickshell-display-modes"
  WlrLayershell.layer: WlrLayer.Overlay
  exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0
  anchors.bottom: true
  margins.bottom: 90
  implicitWidth: row.implicitWidth + 28
  implicitHeight: 96
  visible: DisplayModes.visible && DisplayModes.modes.length > 1

  Rectangle {
    anchors.fill: parent
    radius: Style.radius
    color: Theme.alpha(Theme.bg, Style.surfaceAlpha)
    border.color: Theme.alpha(Theme.fg, Style.surfaceBorderAlpha)
    border.width: 1

    Row {
      id: row
      anchors.centerIn: parent
      spacing: Style.space

      Repeater {
        model: DisplayModes.modes

        delegate: Rectangle {
          id: option
          required property var modelData
          readonly property bool active: DisplayModes.current === modelData.key
          width: 76
          height: 68
          radius: Style.radiusSmall
          color: option.active
            ? Theme.alpha(Theme.accent, optionArea.containsMouse ? 0.32 : 0.24)
            : Theme.alpha(Theme.fg, optionArea.containsMouse ? 0.14 : 0.06)
          border.width: 1
          border.color: option.active ? Theme.accent : Theme.alpha(Theme.fg, 0.12)

          Column {
            anchors.centerIn: parent
            spacing: Style.space

            Icon {
              anchors.horizontalCenter: parent.horizontalCenter
              name: option.modelData.icon
              color: option.active ? Theme.accent : Theme.fg
              size: Style.iconMedium
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: option.modelData.label
              color: option.active ? Theme.accent : Theme.fgDim
              font.family: Style.fontFamily
              font.pixelSize: Style.fontCaption
            }
          }

          MouseArea {
            id: optionArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: DisplayModes.pick(option.modelData.key)
          }
        }
      }
    }
  }
}
