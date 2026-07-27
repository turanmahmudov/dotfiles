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
    visible: area.containsMouse
    topLeftRadius: root.isFirst ? Style.radiusSmall : 0
    topRightRadius: root.isFirst ? Style.radiusSmall : 0
    bottomLeftRadius: root.isLast ? Style.radiusSmall : 0
    bottomRightRadius: root.isLast ? Style.radiusSmall : 0
    color: Theme.alpha(Theme.fg, 0.06)
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: 1
    visible: !root.isFirst
    color: Theme.alpha(Theme.fg, 0.12)
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
    font.pixelSize: Style.fontSize - 5
  }

  Icon {
    id: chevronIcon
    anchors.right: parent.right
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    size: 13
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
    spacing: 2

    Text {
      width: parent.width
      elide: Text.ElideRight
      text: root.label
      color: Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 4
      font.bold: true
    }

    Text {
      width: parent.width
      elide: Text.ElideRight
      visible: root.sublabel.length > 0
      text: root.sublabel
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 5
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
