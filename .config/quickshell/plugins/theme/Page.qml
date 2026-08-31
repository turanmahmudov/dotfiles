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

  Row {
    width: parent.width
    spacing: 6

    Repeater {
      model: panel.modes

      delegate: Rectangle {
        id: modePill
        required property var modelData
        readonly property bool active: Themes.mode === modelData.key
        readonly property bool available: Themes.hasMode(Themes.family, modelData.key)
        width: (parent.width - 6) / 2
        height: 34
        radius: Style.radiusSmall
        opacity: available ? 1 : 0.45
        color: active ? Theme.alpha(Theme.accent, modeArea.containsMouse ? 0.28 : 0.2) : Theme.alpha(Theme.fg, modeArea.containsMouse ? 0.12 : 0.06)

        Row {
          anchors.centerIn: parent
          spacing: 6

          Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: modePill.modelData.icon
            color: modePill.active ? Theme.accent : Theme.fg
            size: 16
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: modePill.modelData.label
            color: modePill.active ? Theme.accent : Theme.fg
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize - 1
          }
        }

        MouseArea {
          id: modeArea
          anchors.fill: parent
          hoverEnabled: true
          enabled: modePill.available
          cursorShape: modePill.available ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: Themes.setMode(modePill.modelData.key)
        }
      }
    }
  }

  SectionHeader {
    text: "Palette"
  }

  Column {
    width: parent.width
    spacing: 6

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
        color: active ? Theme.alpha(Theme.accent, familyArea.containsMouse ? 0.28 : 0.2) : Theme.alpha(Theme.fg, familyArea.containsMouse ? 0.12 : 0.06)

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
          spacing: 2

          Text {
            width: parent.width
            elide: Text.ElideRight
            text: familyRow.modelData.displayName
            color: familyRow.active ? Theme.accent : Theme.fg
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize - 1
            font.bold: familyRow.active
          }

          Text {
            width: parent.width
            elide: Text.ElideRight
            text: familyRow.modelData.modes.join("  ·  ")
            color: Theme.fgDim
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize - 3
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
