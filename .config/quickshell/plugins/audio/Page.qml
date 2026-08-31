import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "Sound"

  function resolveDeviceName(node) {
    return node ? (node.description || node.nickname || node.name || "Device") : ""
  }

  Item {
    width: parent.width
    height: 24

    Icon {
      id: outIcon
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      name: Icons.volume(Audio.muted, Audio.volume)
      color: Audio.muted ? Theme.fgDim : Theme.fg
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Audio.toggleMute()
      }
    }

    Slider {
      anchors.left: outIcon.right
      anchors.leftMargin: 10
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      value: Audio.volume
      onMoved: (v) => Audio.setVolume(v)
    }
  }

  Item {
    width: parent.width
    height: 24

    Icon {
      id: inIcon
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      name: Audio.micMuted ? "mic-off" : "mic"
      color: Audio.micMuted ? Theme.fgDim : Theme.fg
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Audio.toggleMicMute()
      }
    }

    Slider {
      anchors.left: inIcon.right
      anchors.leftMargin: 10
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      value: Audio.micVolume
      onMoved: (v) => Audio.setMicVolume(v)
    }
  }

  SectionHeader {
    visible: sinkList.count > 0
    text: "Output device"
  }

  Column {
    width: parent.width
    spacing: 4

    Repeater {
      id: sinkList
      model: Audio.listSinks()

      delegate: Rectangle {
        id: sinkRow
        required property var modelData
        readonly property bool active: Audio.sinkNode && modelData && Audio.sinkNode.id === modelData.id
        width: parent.width
        height: 30
        radius: Style.radiusSmall
        color: active ? Theme.alpha(Theme.accent, sinkArea.containsMouse ? 0.28 : 0.2) : Theme.alpha(Theme.fg, sinkArea.containsMouse ? 0.12 : 0.06)

        Text {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          elide: Text.ElideRight
          text: panel.resolveDeviceName(sinkRow.modelData)
          color: sinkRow.active ? Theme.accent : Theme.fg
          font.family: Style.fontFamily
          font.pixelSize: Style.fontSize - 1
        }

        MouseArea {
          anchors.fill: parent
          id: sinkArea
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Audio.setDefaultSink(sinkRow.modelData)
        }
      }
    }
  }

  SectionHeader {
    visible: sourceList.count > 0
    text: "Input device"
  }

  Column {
    width: parent.width
    spacing: 4

    Repeater {
      id: sourceList
      model: Audio.listSources()

      delegate: Rectangle {
        id: srcRow
        required property var modelData
        readonly property bool active: Audio.sourceNode && modelData && Audio.sourceNode.id === modelData.id
        width: parent.width
        height: 30
        radius: Style.radiusSmall
        color: active ? Theme.alpha(Theme.accent, srcArea.containsMouse ? 0.28 : 0.2) : Theme.alpha(Theme.fg, srcArea.containsMouse ? 0.12 : 0.06)

        Text {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          elide: Text.ElideRight
          text: panel.resolveDeviceName(srcRow.modelData)
          color: srcRow.active ? Theme.accent : Theme.fg
          font.family: Style.fontFamily
          font.pixelSize: Style.fontSize - 1
        }

        MouseArea {
          anchors.fill: parent
          id: srcArea
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Audio.setDefaultSource(srcRow.modelData)
        }
      }
    }
  }

  Rectangle {
    width: parent.width
    height: 34
    radius: Style.radiusSmall
    color: pavuArea.containsMouse ? Theme.alpha(Theme.fg, 0.12) : Theme.alpha(Theme.fg, 0.06)

    Text {
      anchors.centerIn: parent
      text: "Sound settings"
      color: Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 1
    }

    MouseArea {
      id: pavuArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        Quickshell.execDetached(["pavucontrol"])
        panel.requestClose()
      }
    }
  }
}
