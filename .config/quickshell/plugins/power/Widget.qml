import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  readonly property bool critical: Battery.present && Battery.percent <= 10 && !Battery.charging
  readonly property bool showPercent: !(settings && settings.showPercent === false)

  function describeBattery() {
    if (!Battery.present)
      return ""
    var state = Battery.full ? "Fully charged" : (Battery.charging ? "Charging" : "On battery")
    return Battery.percent + "%  ·  " + state + "  ·  "
  }

  tooltipText: describeBattery() + "Profile: " + Battery.profile
  onClicked: openPanel()

  Row {
    spacing: 4

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      name: Battery.present ? Icons.battery(Battery.percent, Battery.charging) : Icons.profile(Battery.profile)
      color: root.critical ? Theme.urgent : (root.hovered ? Theme.fgDim : Theme.fg)

      SequentialAnimation on opacity {
        running: root.critical
        loops: Animation.Infinite
        NumberAnimation { to: 0.4; duration: 1000; easing.type: Easing.InOutQuad }
        NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutQuad }
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: Battery.present && root.showPercent
      text: Battery.percent + "%"
      color: root.critical ? Theme.urgent : (root.hovered ? Theme.fgDim : Theme.fg)
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize
    }
  }
}
