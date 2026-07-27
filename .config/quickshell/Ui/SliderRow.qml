import QtQuick
import qs.Commons

// Card holding one slider, with an icon that can act as a button and an
// optional chevron to the owning page.
Item {
  id: root
  property string iconName: ""
  property real value: 0
  property bool iconIsButton: false
  property bool hasDetail: false
  property string valueText: Math.round(root.value * 100) + "%"

  signal moved(real value)
  signal iconClicked()
  signal detailRequested()

  implicitHeight: 45
  height: implicitHeight

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusSmall
    color: Theme.alpha(Theme.fg, 0.04)
    border.width: 1
    border.color: Theme.alpha(Theme.fg, 0.12)
  }

  Rectangle {
    id: iconBox
    anchors.left: parent.left
    anchors.leftMargin: 9
    anchors.verticalCenter: parent.verticalCenter
    width: 28
    height: 28
    radius: 7
    color: iconArea.containsMouse && root.iconIsButton ? Theme.alpha(Theme.accent, 0.16) : Theme.alpha(Theme.fg, 0.07)

    Icon {
      anchors.centerIn: parent
      size: 16
      name: root.iconName
      color: iconArea.containsMouse && root.iconIsButton ? Theme.accent : Theme.fg
    }

    MouseArea {
      id: iconArea
      anchors.fill: parent
      hoverEnabled: root.iconIsButton
      enabled: root.iconIsButton
      cursorShape: Qt.PointingHandCursor
      onClicked: root.iconClicked()
    }
  }

  Text {
    id: valueLabel
    anchors.right: root.hasDetail ? chevron.left : parent.right
    anchors.rightMargin: root.hasDetail ? 4 : 10
    anchors.verticalCenter: parent.verticalCenter
    horizontalAlignment: Text.AlignRight
    width: 34
    text: root.valueText
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize - 5
  }

  Slider {
    anchors.left: iconBox.right
    anchors.leftMargin: 9
    anchors.right: valueLabel.left
    anchors.rightMargin: 9
    anchors.verticalCenter: parent.verticalCenter
    value: root.value
    onMoved: (v) => root.moved(v)
  }

  Item {
    id: chevron
    anchors.right: parent.right
    anchors.rightMargin: 6
    anchors.verticalCenter: parent.verticalCenter
    width: 24
    height: 24
    visible: root.hasDetail

    Icon {
      anchors.centerIn: parent
      size: 14
      name: "chevron-right"
      color: chevronArea.containsMouse ? Theme.accent : Theme.fgDim
    }

    MouseArea {
      id: chevronArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.detailRequested()
    }
  }
}
