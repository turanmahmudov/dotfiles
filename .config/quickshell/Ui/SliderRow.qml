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
  property bool detailOpen: false
  // Names what the slider is acting on, such as the device it plays through.
  property string caption: ""
  property string valueText: Math.round(root.value * 100) + "%"

  signal moved(real value)
  signal iconClicked()
  signal detailRequested()

  implicitHeight: root.caption.length > 0 ? 58 : 45
  height: implicitHeight

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusSmall
    color: Theme.alpha(Theme.fg, Style.cardAlpha)
    border.width: 1
    border.color: Theme.alpha(Theme.fg, Style.cardBorderAlpha)
  }

  Rectangle {
    id: iconBox
    anchors.left: parent.left
    anchors.leftMargin: 9
    anchors.verticalCenter: root.caption.length > 0 ? undefined : parent.verticalCenter
    anchors.top: root.caption.length > 0 ? parent.top : undefined
    anchors.topMargin: root.caption.length > 0 ? 8 : 0
    width: 28
    height: 28
    radius: 7
    color: iconArea.containsMouse && root.iconIsButton ? Theme.alpha(Theme.accent, Style.cardActiveAlpha) : Theme.alpha(Theme.fg, 0.07)

    Icon {
      anchors.centerIn: parent
      size: Style.iconSmall
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
    anchors.verticalCenter: iconBox.verticalCenter
    horizontalAlignment: Text.AlignRight
    width: 34
    text: root.valueText
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontMicro
  }

  Slider {
    anchors.left: iconBox.right
    anchors.leftMargin: 9
    anchors.right: valueLabel.left
    anchors.rightMargin: 9
    anchors.verticalCenter: iconBox.verticalCenter
    value: root.value
    onMoved: (v) => root.moved(v)
  }

  Text {
    anchors.left: iconBox.right
    anchors.leftMargin: 9
    anchors.right: chevron.left
    anchors.rightMargin: 6
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 8
    visible: root.caption.length > 0
    elide: Text.ElideRight
    text: root.caption
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontCaption
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
      size: Style.iconTiny
      name: "chevron-right"
      color: (chevronArea.containsMouse || root.detailOpen) ? Theme.accent : Theme.fgDim
      rotation: root.detailOpen ? 90 : 0

      Behavior on rotation {
        NumberAnimation {
          duration: Style.anim
          easing.type: Easing.OutCubic
        }
      }
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
