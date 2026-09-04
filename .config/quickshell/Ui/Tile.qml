import QtQuick
import qs.Commons

// One control that renders big or small. The section it sits in owns the size:
// big shows a sublabel and a split arrow to the owning page, small is a labelled
// icon that reacts to one click.
Item {
  id: root

  property string iconName: ""
  property string label: ""
  property string sublabel: ""
  property bool active: false
  property bool compact: false
  property bool hasDetail: false

  signal triggered()
  signal detailRequested()

  activeFocusOnTab: true
  Keys.onReturnPressed: root.triggered()
  Keys.onEnterPressed: root.triggered()
  Keys.onSpacePressed: root.triggered()

  readonly property bool showsDetail: hasDetail && !compact
  readonly property int detailWidth: 30

  implicitHeight: compact ? 43 : 58
  height: implicitHeight

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusSmall
    color: root.active
      ? Theme.alpha(Theme.accent, (root.compact && smallArea.containsMouse) ? Style.cardActiveHoverAlpha : Style.cardActiveAlpha)
      : Theme.alpha(Theme.fg, root.compact ? (smallArea.containsMouse ? Style.cardHoverAlpha : Style.cardAlpha) : Style.cardAlpha)
    border.width: 1
    border.color: root.active
      ? Theme.alpha(Theme.accent, Style.cardActiveBorderAlpha)
      : Theme.alpha(Theme.fg, Style.cardBorderAlpha)

    Behavior on color {
      ColorAnimation {
        duration: Style.animFast
      }
    }
  }

  FocusRing {}

  Item {
    id: big
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: root.showsDetail ? detail.left : parent.right
    visible: !root.compact

    // Only the outer corners are rounded, so the highlight follows the tile
    // outline instead of drawing a floating rounded box inside it.
    Rectangle {
      anchors.fill: parent
      anchors.leftMargin: 1
      anchors.topMargin: 1
      anchors.bottomMargin: 1
      topLeftRadius: Style.radiusSmall
      bottomLeftRadius: Style.radiusSmall
      opacity: bigArea.containsMouse ? 1 : 0
      color: Theme.alpha(Theme.fg, Style.cardHoverAlpha)

      Behavior on opacity {
        NumberAnimation {
          duration: Style.animFast
        }
      }
    }

    Rectangle {
      id: iconBox
      anchors.left: parent.left
      anchors.leftMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      width: 25
      height: 25
      radius: 7
      color: Theme.alpha(Theme.bgAlt, 0.35)

      Icon {
        anchors.centerIn: parent
        name: root.iconName
        color: root.active ? Theme.accent : Theme.fg
      }
    }

    Column {
      anchors.left: iconBox.right
      anchors.leftMargin: 8
      anchors.right: parent.right
      anchors.rightMargin: 6
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.spaceHair

      Text {
        width: parent.width
        elide: Text.ElideRight
        text: root.label
        color: root.active ? Theme.accent : Theme.fg
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        font.bold: true
      }

      Text {
        width: parent.width
        elide: Text.ElideRight
        visible: root.sublabel.length > 0
        text: root.sublabel
        color: Theme.fgDim
        font.family: Style.fontFamily
        font.pixelSize: Style.fontMicro
      }
    }

    MouseArea {
      id: bigArea
      anchors.fill: parent
      enabled: !root.compact
      hoverEnabled: !root.compact
      cursorShape: Qt.PointingHandCursor
      onClicked: root.triggered()
    }
  }

  Item {
    id: detail
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: root.detailWidth
    visible: root.showsDetail

    Rectangle {
      anchors.fill: parent
      anchors.rightMargin: 1
      anchors.topMargin: 1
      anchors.bottomMargin: 1
      topRightRadius: Style.radiusSmall
      bottomRightRadius: Style.radiusSmall
      color: detailArea.containsMouse ? Theme.alpha(Theme.fg, Style.cardHoverAlpha) : Theme.alpha(Theme.bgAlt, 0.28)
    }

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.margins: 1
      width: 1
      color: Theme.alpha(Theme.fg, Style.cardBorderAlpha)
    }

    Icon {
      anchors.centerIn: parent
      size: Style.iconTiny
      name: "chevron-right"
      color: detailArea.containsMouse ? Theme.fg : Theme.fgDim
    }

    MouseArea {
      id: detailArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.detailRequested()
    }
  }

  Row {
    anchors.left: parent.left
    anchors.leftMargin: 8
    anchors.right: parent.right
    anchors.rightMargin: 6
    anchors.verticalCenter: parent.verticalCenter
    visible: root.compact
    spacing: 7

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      size: Style.iconSmall
      name: root.iconName
      color: root.active ? Theme.accent : Theme.fg
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 23
      elide: Text.ElideRight
      text: root.label
      color: root.active ? Theme.accent : Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontMicro
    }
  }

  MouseArea {
    id: smallArea
    anchors.fill: parent
    enabled: root.compact
    hoverEnabled: root.compact
    cursorShape: Qt.PointingHandCursor
    onClicked: root.triggered()
  }
}
