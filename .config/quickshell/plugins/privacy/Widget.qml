import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  shown: Privacy.mic || Privacy.cam || Privacy.screen
  tooltipText: [
    Privacy.screen ? "Screen sharing" : "",
    Privacy.cam ? "Camera" : "",
    Privacy.mic ? "Microphone" : ""
  ].filter(function (s) { return s.length > 0 }).join("  ·  ")

  Row {
    spacing: Style.spaceTight

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      visible: Privacy.screen
      name: "screen-share"
      color: Theme.urgent
    }

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      visible: Privacy.cam
      name: "video"
      color: Theme.urgent
    }

    Icon {
      anchors.verticalCenter: parent.verticalCenter
      visible: Privacy.mic
      name: "mic"
      color: Theme.urgent
    }
  }
}
