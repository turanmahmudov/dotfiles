import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  shown: Recorder.recording
  tooltipText: "Recording " + Recorder.elapsedLabel + (Recorder.withAudio ? "  ·  with audio" : "") + "  ·  click to stop"
  onClicked: Recorder.stop()

  Row {
    spacing: Style.spaceTight

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: 10
      height: 10
      radius: 5
      color: Theme.error

      SequentialAnimation on opacity {
        running: Recorder.recording
        loops: Animation.Infinite
        NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutQuad }
        NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Recorder.elapsedLabel
      color: root.hovered ? Theme.fgDim : Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontTitle
    }
  }
}
