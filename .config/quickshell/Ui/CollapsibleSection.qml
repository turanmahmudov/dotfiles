import QtQuick
import qs.Commons

// A titled block that folds. The collapsed row still shows the value, so the
// current choice reads without opening the block.
//
// The folding itself lives in Reveal.
Column {
  id: section

  property string title: ""
  property string value: ""
  property bool open: false
  property int bodySpacing: 4

  default property alias body: revealBody.content

  width: parent ? parent.width : 0
  spacing: Style.space
  topPadding: 8

  Rectangle {
    width: parent.width
    height: Style.rowHeight
    radius: Style.radiusSmall
    color: section.open
      ? Theme.alpha(Theme.accent, headerArea.containsMouse ? Style.cardActiveHoverAlpha : Style.cardActiveAlpha)
      : Theme.alpha(Theme.fg, headerArea.containsMouse ? Style.cardHoverAlpha : Style.cardAlpha)
    border.width: 1
    border.color: section.open
      ? Theme.alpha(Theme.accent, Style.cardActiveBorderAlpha)
      : Theme.alpha(Theme.fg, Style.cardBorderAlpha)

    Behavior on color {
      ColorAnimation {
        duration: Style.animFast
      }
    }

    Behavior on border.color {
      ColorAnimation {
        duration: Style.animFast
      }
    }

    Icon {
      id: chevron
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      name: "chevron-right"
      color: section.open ? Theme.accent : Theme.fgDim
      size: Style.iconTiny
      rotation: section.open ? 90 : 0

      Behavior on rotation {
        NumberAnimation {
          duration: Style.anim
          easing.type: Easing.OutCubic
        }
      }
    }

    Text {
      id: titleLabel
      anchors.left: chevron.right
      anchors.leftMargin: 8
      anchors.right: valueLabel.left
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
      text: section.title
      color: section.open ? Theme.accent : Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontBody
    }

    Text {
      id: valueLabel
      anchors.right: parent.right
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(implicitWidth, section.width * 0.5)
      horizontalAlignment: Text.AlignRight
      elide: Text.ElideRight
      text: section.value
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontCaption
      opacity: (section.value.length > 0 && !section.open) ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: Style.animFast
        }
      }
    }

    FocusRing {
      target: section
    }

    MouseArea {
      id: headerArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: section.open = !section.open
    }
  }

  Reveal {
    id: revealBody
    open: section.open
    bodySpacing: section.bodySpacing
  }
}
