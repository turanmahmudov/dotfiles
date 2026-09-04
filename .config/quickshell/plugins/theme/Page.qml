import QtQuick
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "Appearance"

  readonly property var modes: [
    { "key": "dark", "label": "Dark", "icon": "moon" },
    { "key": "light", "label": "Light", "icon": "sun" }
  ]

  Component.onCompleted: Themes.refresh()

  PillRow {
    entries: {
      var out = []
      for (var i = 0; i < panel.modes.length; i++) {
        var m = panel.modes[i]
        out.push({
          "key": m.key,
          "label": m.label,
          "icon": m.icon,
          "available": Themes.hasMode(Themes.family, m.key)
        })
      }
      return out
    }
    current: Themes.mode
    onPicked: (key) => Themes.setMode(key)
  }

  SectionHeader {
    text: "Palette"
  }

  Column {
    width: parent.width
    spacing: Style.spaceTight

    Repeater {
      model: Themes.families

      delegate: Rectangle {
        id: familyRow
        required property var modelData
        readonly property bool active: Themes.family === modelData.family
        readonly property string preview: Themes.findPreview(modelData, Themes.mode)
        width: parent.width
        height: 52
        radius: Style.radiusSmall
        color: active
          ? Theme.alpha(Theme.accent, familyArea.containsMouse ? Style.cardActiveHoverAlpha : Style.cardActiveAlpha)
          : Theme.alpha(Theme.fg, familyArea.containsMouse ? Style.cardHoverAlpha : Style.cardAlpha)
        border.width: 1
        border.color: active
          ? Theme.alpha(Theme.accent, Style.cardActiveBorderAlpha)
          : Theme.alpha(Theme.fg, Style.cardBorderAlpha)

        Behavior on color {
          ColorAnimation {
            duration: Style.animFast
          }
        }

        Rectangle {
          id: thumbFrame
          anchors.left: parent.left
          anchors.leftMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          width: 64
          height: 36
          radius: 4
          clip: true
          color: Theme.alpha(Theme.fg, 0.1)

          Image {
            anchors.fill: parent
            visible: status === Image.Ready
            source: familyRow.preview.length > 0 ? ("file://" + familyRow.preview) : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 128
            sourceSize.height: 72
            asynchronous: true
            smooth: true
          }
        }

        Column {
          anchors.left: thumbFrame.right
          anchors.leftMargin: 10
          anchors.right: parent.right
          anchors.rightMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.spaceHair

          Text {
            width: parent.width
            elide: Text.ElideRight
            text: familyRow.modelData.displayName
            color: familyRow.active ? Theme.accent : Theme.fg
            font.family: Style.fontFamily
            font.pixelSize: Style.fontBody
            font.bold: familyRow.active
          }

          Text {
            width: parent.width
            elide: Text.ElideRight
            text: familyRow.modelData.modes.join("  ·  ")
            color: Theme.fgDim
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
          }
        }

        MouseArea {
          id: familyArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Themes.apply(familyRow.modelData.family, Themes.mode)
        }
      }
    }
  }
}
