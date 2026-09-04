import QtQuick
import qs.Commons
import qs.Ui

Rectangle {
  id: bar

  property string tipText: ""
  property real tipCenterX: 0

  implicitWidth: row.implicitWidth + 24
  implicitHeight: 56
  radius: Style.radius
  color: Theme.alpha(Theme.bg, Style.surfaceAlpha)
  border.color: Theme.alpha(Theme.fg, Style.surfaceBorderAlpha)
  border.width: 1

  MouseArea {
    anchors.fill: parent
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space

    Repeater {
      model: [
        { m: "region", icon: "crop", label: "Region  r" },
        { m: "window", icon: "app-window", label: "Window  w" },
        { m: "monitor", icon: "monitor", label: "Monitor  s" }
      ]

      Rectangle {
        id: modeBtn
        required property var modelData
        readonly property bool selected: Screenshot.mode === modelData.m
        width: 44
        height: 44
        radius: Style.radiusSmall
        color: modeBtn.selected ? Theme.alpha(Theme.accent, 0.25)
               : (modeMa.containsMouse ? Theme.alpha(Theme.fg, 0.10) : "transparent")
        Behavior on color { ColorAnimation { duration: 100 } }

        Icon {
          anchors.centerIn: parent
          name: modeBtn.modelData.icon
          size: Style.iconMedium
          color: modeBtn.selected ? Theme.accent : Theme.fg
        }

        MouseArea {
          id: modeMa
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: {
            bar.tipText = modeBtn.modelData.label
            bar.tipCenterX = modeBtn.mapToItem(bar, modeBtn.width / 2, 0).x
          }
          onExited: if (bar.tipText === modeBtn.modelData.label) bar.tipText = ""
          onClicked: Screenshot.setMode(modeBtn.modelData.m)
        }
      }
    }

    Rectangle {
      width: 1
      height: 32
      anchors.verticalCenter: parent.verticalCenter
      color: Theme.alpha(Theme.fg, 0.15)
    }

    Rectangle {
      id: delayChip
      readonly property bool on: Screenshot.delaySeconds > 0
      width: 68
      height: 44
      radius: Style.radiusSmall
      color: delayChip.on ? Theme.alpha(Theme.accent, 0.25)
             : (delayMa.containsMouse ? Theme.alpha(Theme.fg, 0.10) : "transparent")
      Behavior on color { ColorAnimation { duration: 100 } }

      Row {
        anchors.centerIn: parent
        spacing: Style.spaceTight
        Icon {
          anchors.verticalCenter: parent.verticalCenter
          name: "timer"
          size: Style.iconMedium
          color: delayChip.on ? Theme.accent : Theme.fg
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: Screenshot.delaySeconds > 0 ? Screenshot.delaySeconds + "s" : "off"
          color: delayChip.on ? Theme.accent : Theme.fg
          font.family: Style.fontFamily
          font.pixelSize: Style.fontTitle
        }
      }

      MouseArea {
        id: delayMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
          bar.tipText = "Delay before capture"
          bar.tipCenterX = delayChip.mapToItem(bar, delayChip.width / 2, 0).x
        }
        onExited: if (bar.tipText === "Delay before capture") bar.tipText = ""
        onClicked: Screenshot.cycleDelay()
      }
    }
  }

  Rectangle {
    id: tip
    visible: bar.tipText !== ""
    z: 100
    radius: Style.tooltipRadius
    color: Theme.bg
    border.color: Theme.fg
    border.width: 1
    width: tipLabel.implicitWidth + 20
    height: tipLabel.implicitHeight + 12
    x: Math.max(0, Math.min(bar.width - width, bar.tipCenterX - width / 2))
    y: -height - 8

    Text {
      id: tipLabel
      anchors.centerIn: parent
      text: bar.tipText
      color: Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontBody
    }
  }
}
