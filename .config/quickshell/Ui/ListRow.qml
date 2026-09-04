import QtQuick
import qs.Commons

// Standalone bordered row for lists of things you pick: networks, devices,
// packages, profiles.
Item {
  id: root
  property string iconName: ""
  property string label: ""
  property string sublabel: ""
  property string value: ""
  property bool active: false
  property bool enabled: true
  property color valueColor: root.active ? Theme.accent : Theme.fgDim
  // Optional trailing icon, for rows whose value carries its own symbol such as
  // a battery level or a signal strength.
  property string valueIconName: ""
  property color valueIconColor: root.active ? Theme.accent : Theme.fgDim

  signal clicked()
  signal rightClicked()

  activeFocusOnTab: root.enabled
  Keys.onReturnPressed: root.clicked()
  Keys.onEnterPressed: root.clicked()
  Keys.onSpacePressed: root.clicked()

  width: parent ? parent.width : implicitWidth
  // Sized to what the row carries: a plain pick row stays as compact as any
  // other row in the panels, and only a row with a second line grows.
  implicitHeight: root.sublabel.length > 0 ? 46 : Style.rowHeight
  height: implicitHeight

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusSmall
    color: root.active
      ? Theme.alpha(Theme.accent, area.containsMouse ? Style.cardActiveHoverAlpha : Style.cardActiveAlpha)
      : Theme.alpha(Theme.fg, area.containsMouse ? Style.cardHoverAlpha : Style.cardAlpha)
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

  Icon {
    id: leadIcon
    anchors.left: parent.left
    anchors.leftMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    visible: root.iconName.length > 0
    name: root.iconName
    color: root.active ? Theme.accent : Theme.fg
  }

  Icon {
    id: valueIcon
    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    visible: root.valueIconName.length > 0
    name: root.valueIconName
    color: root.valueIconColor
    size: Style.iconSmall
  }

  Text {
    id: valueLabel
    anchors.right: valueIcon.visible ? valueIcon.left : parent.right
    anchors.rightMargin: valueIcon.visible ? 5 : 10
    anchors.verticalCenter: parent.verticalCenter
    text: root.value
    color: root.valueColor
    font.family: Style.fontFamily
    font.pixelSize: Style.fontCaption
  }

  Column {
    anchors.left: root.iconName.length > 0 ? leadIcon.right : parent.left
    anchors.leftMargin: root.iconName.length > 0 ? 9 : 10
    anchors.right: valueLabel.left
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spaceHair

    Text {
      width: parent.width
      elide: Text.ElideRight
      text: root.label
      color: root.active ? Theme.accent : Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontBody
      font.bold: root.sublabel.length > 0
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
    hoverEnabled: root.enabled
    enabled: root.enabled
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (m) => m.button === Qt.RightButton ? root.rightClicked() : root.clicked()
  }
}
