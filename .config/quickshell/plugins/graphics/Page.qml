import QtQuick
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "Graphics mode"

  Column {
    width: parent.width
    spacing: 6

    Repeater {
      model: Prime.modes

      delegate: Rectangle {
        id: pill
        required property var modelData
        readonly property bool active: Prime.mode === modelData
        readonly property bool pending: Prime.pendingMode === modelData && !active
        width: parent.width
        height: 36
        radius: Style.radiusSmall
        color: pill.active
          ? Theme.alpha(Theme.accent, pillArea.containsMouse ? 0.28 : 0.2)
          : Theme.alpha(Theme.fg, pillArea.containsMouse ? 0.12 : 0.06)

        Row {
          anchors.left: parent.left
          anchors.leftMargin: 10
          anchors.right: parent.right
          anchors.rightMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: Prime.resolveIcon(pill.modelData)
            color: pill.active ? Theme.accent : Theme.fg
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Prime.resolveLabel(pill.modelData) + (pill.pending ? "  ·  after logout" : "")
            color: pill.pending ? Theme.warning : (pill.active ? Theme.accent : Theme.fg)
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
          }
        }

        MouseArea {
          id: pillArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Prime.selectMode(pill.modelData)
        }
      }
    }
  }
}
