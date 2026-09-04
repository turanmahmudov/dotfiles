import QtQuick
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "Battery"

  function resolveProfileLabel(p) {
    if (p === "power-saver")
      return "Power Saver"
    if (p === "performance")
      return "Performance"
    return "Balanced"
  }

  Rectangle {
    width: parent.width
    implicitHeight: batteryRow.implicitHeight + 20
    height: implicitHeight
    radius: Style.radiusSmall
    color: Theme.alpha(Theme.fg, Style.cardAlpha)
    border.width: 1
    border.color: Theme.alpha(Theme.fg, Style.cardBorderAlpha)
    visible: Battery.present

    Row {
      id: batteryRow
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 10
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space

      Icon {
        anchors.verticalCenter: parent.verticalCenter
        size: Style.iconLarge
        name: Icons.battery(Battery.percent, Battery.charging)
        color: Theme.fg
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spaceHair

        Text {
          text: Battery.percent + "%"
          color: Theme.fg
          font.family: Style.fontFamily
          font.pixelSize: Style.fontTitle
          font.bold: true
        }

        Text {
          text: {
            var state = Battery.full ? "Fully charged" : (Battery.charging ? "Charging" : "On battery")
            return Battery.timeSummary.length > 0 ? (state + "  ·  " + Battery.timeSummary) : state
          }
          color: Theme.fgDim
          font.family: Style.fontFamily
          font.pixelSize: Style.fontBody
        }
      }
    }
  }

  SectionHeader {
    text: "Power profile"
  }

  Column {
    width: parent.width
    spacing: Style.spaceTight

    Repeater {
      model: Battery.profiles

      delegate: ListRow {
        required property var modelData
        iconName: Icons.profile(modelData)
        label: panel.resolveProfileLabel(modelData)
        active: Battery.profile === modelData
        onClicked: Battery.setProfile(modelData)
      }
    }
  }
}
