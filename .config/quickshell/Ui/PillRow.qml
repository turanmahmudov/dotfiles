import QtQuick
import qs.Commons

// A row of equal width choices, one of them current. Owns the width split, so
// callers do not repeat the arithmetic for every panel that offers a choice.
Item {
  id: root

  // Entries are { key, label, icon }; label and icon are both optional.
  property var entries: []
  property var current: ""
  property int spacing: Style.spaceTight
  property int rowHeight: Style.rowHeight

  signal picked(var key)

  width: parent ? parent.width : implicitWidth
  implicitHeight: root.rowHeight
  height: implicitHeight

  Row {
    anchors.fill: parent
    spacing: root.spacing

    Repeater {
      model: root.entries

      delegate: Rectangle {
        id: pill
        required property var modelData
        readonly property bool active: root.current === modelData.key
        readonly property bool available: modelData.available !== false

        activeFocusOnTab: pill.available
        Keys.onReturnPressed: root.picked(pill.modelData.key)
        Keys.onEnterPressed: root.picked(pill.modelData.key)
        Keys.onSpacePressed: root.picked(pill.modelData.key)

        width: (root.width - root.spacing * (root.entries.length - 1)) / Math.max(1, root.entries.length)
        height: root.rowHeight
        radius: Style.radiusSmall
        opacity: available ? 1 : 0.45
        color: pill.active
          ? Theme.alpha(Theme.accent, pillArea.containsMouse ? Style.cardActiveHoverAlpha : Style.cardActiveAlpha)
          : Theme.alpha(Theme.fg, pillArea.containsMouse ? Style.cardHoverAlpha : Style.cardAlpha)
        border.width: 1
        border.color: pill.active
          ? Theme.alpha(Theme.accent, Style.cardActiveBorderAlpha)
          : Theme.alpha(Theme.fg, Style.cardBorderAlpha)

        Behavior on color {
          ColorAnimation {
            duration: Style.animFast
          }
        }

        Row {
          anchors.centerIn: parent
          spacing: Style.spaceTight

          Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: String(pill.modelData.icon || "").length > 0
            name: pill.modelData.icon || ""
            color: pill.active ? Theme.accent : Theme.fg
            size: Style.iconSmall
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: String(pill.modelData.label || "").length > 0
            text: pill.modelData.label || ""
            color: pill.active ? Theme.accent : Theme.fg
            font.family: Style.fontFamily
            font.pixelSize: Style.fontBody
          }
        }

        FocusRing {}

        MouseArea {
          id: pillArea
          anchors.fill: parent
          hoverEnabled: pill.available
          enabled: pill.available
          cursorShape: pill.available ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: root.picked(pill.modelData.key)
        }
      }
    }
  }
}
