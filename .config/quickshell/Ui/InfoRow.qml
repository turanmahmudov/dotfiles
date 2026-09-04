import QtQuick
import qs.Commons

// One row inside an InfoList: icon, title over subtitle, trailing value and
// chevron. Fills its parent width, which a bare Item does not do by default.
Item {
  id: root
  property string iconName: ""
  property string label: ""
  property string sublabel: ""
  property string value: ""
  property bool hasChevron: true

  signal clicked()

  activeFocusOnTab: true
  Keys.onReturnPressed: root.clicked()
  Keys.onEnterPressed: root.clicked()
  Keys.onSpacePressed: root.clicked()

  // Derived for rows written straight into a list, and set by the host when the
  // row sits inside a loader that hides its siblings.
  property bool isFirst: parent && parent.children.length > 0 && parent.children[0] === root
  property bool isLast: parent && parent.children.length > 0
    && parent.children[parent.children.length - 1] === root

  width: parent ? parent.width : implicitWidth
  implicitHeight: 46
  height: implicitHeight

  // The end rows follow the list's rounded corners, otherwise the highlight
  // squares off outside them.
  Rectangle {
    anchors.fill: parent
    opacity: area.containsMouse ? 1 : 0
    topLeftRadius: root.isFirst ? Style.radiusSmall : 0
    topRightRadius: root.isFirst ? Style.radiusSmall : 0
    bottomLeftRadius: root.isLast ? Style.radiusSmall : 0
    bottomRightRadius: root.isLast ? Style.radiusSmall : 0
    color: Theme.alpha(Theme.fg, Style.cardHoverAlpha)

    Behavior on opacity {
      NumberAnimation {
        duration: Style.animFast
      }
    }
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: 1
    visible: !root.isFirst
    color: Theme.alpha(Theme.fg, Style.cardBorderAlpha)
  }

  Icon {
    id: leadIcon
    anchors.left: parent.left
    anchors.leftMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    name: root.iconName
    color: Theme.fgDim
  }

  Text {
    id: valueLabel
    anchors.right: root.hasChevron ? chevronIcon.left : parent.right
    anchors.rightMargin: root.hasChevron ? 6 : 10
    anchors.verticalCenter: parent.verticalCenter
    text: root.value
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontMicro
  }

  Icon {
    id: chevronIcon
    anchors.right: parent.right
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    size: Style.iconTiny
    visible: root.hasChevron
    name: "chevron-right"
    color: area.containsMouse ? Theme.fg : Theme.fgDim
  }

  Column {
    anchors.left: leadIcon.right
    anchors.leftMargin: 9
    anchors.right: valueLabel.left
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spaceHair

    Text {
      width: parent.width
      elide: Text.ElideRight
      text: root.label
      color: Theme.fg
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

  FocusRing {}

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
