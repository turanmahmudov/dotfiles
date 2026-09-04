import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "Sound"

  property bool outputOpen: false
  property bool inputOpen: false

  readonly property int appCount: playbackList.count + recordList.count

  function resolveDeviceName(node) {
    return node ? (node.description || node.nickname || node.name || "Device") : ""
  }

  // The description carries the whole controller name, which is too long for a
  // one line summary. The nickname is the part that names the device.
  function resolveShortDeviceName(node) {
    return node ? (node.nickname || node.description || node.name || "Device") : ""
  }

  function formatAppCount(n) {
    if (n === 0)
      return "None"
    return n === 1 ? "1 app" : n + " apps"
  }

  SliderRow {
    width: parent.width
    iconName: Icons.volume(Audio.muted, Audio.volume)
    iconIsButton: true
    caption: panel.resolveShortDeviceName(Audio.sinkNode)
    hasDetail: sinkList.count > 1
    detailOpen: panel.outputOpen
    value: Audio.volume
    onIconClicked: Audio.toggleMute()
    onMoved: (v) => Audio.setVolume(v)
    onDetailRequested: panel.outputOpen = !panel.outputOpen
  }

  Reveal {
    open: panel.outputOpen

    Repeater {
      id: sinkList
      model: Audio.sinks

      delegate: ListRow {
        required property var modelData
        label: panel.resolveDeviceName(modelData)
        active: Audio.sinkNode && modelData && Audio.sinkNode.id === modelData.id
        onClicked: {
          Audio.setDefaultSink(modelData)
          panel.outputOpen = false
        }
      }
    }
  }

  SliderRow {
    width: parent.width
    iconName: Audio.micMuted ? "mic-off" : "mic"
    iconIsButton: true
    caption: panel.resolveShortDeviceName(Audio.sourceNode)
    hasDetail: sourceList.count > 1
    detailOpen: panel.inputOpen
    value: Audio.micVolume
    onIconClicked: Audio.toggleMicMute()
    onMoved: (v) => Audio.setMicVolume(v)
    onDetailRequested: panel.inputOpen = !panel.inputOpen
  }

  Reveal {
    open: panel.inputOpen

    Repeater {
      id: sourceList
      model: Audio.sources

      delegate: ListRow {
        required property var modelData
        label: panel.resolveDeviceName(modelData)
        active: Audio.sourceNode && modelData && Audio.sourceNode.id === modelData.id
        onClicked: {
          Audio.setDefaultSource(modelData)
          panel.inputOpen = false
        }
      }
    }
  }

  CollapsibleSection {
    title: "Applications"
    value: panel.formatAppCount(panel.appCount)

    Text {
      width: parent.width
      wrapMode: Text.WordWrap
      visible: panel.appCount === 0
      text: "No application is using audio."
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontBody
    }

    SectionHeader {
      visible: playbackList.count > 0
      topPadding: 4
      text: "Playing"
    }

    Column {
      width: parent.width
      spacing: Style.space

      Repeater {
        id: playbackList
        model: Audio.playbackStreams

        delegate: StreamRow {
          required property var modelData
          node: modelData
          devices: Audio.sinks
        }
      }
    }

    SectionHeader {
      visible: recordList.count > 0
      topPadding: 4
      text: "Recording"
    }

    Column {
      width: parent.width
      spacing: Style.space

      Repeater {
        id: recordList
        model: Audio.recordStreams

        delegate: StreamRow {
          required property var modelData
          node: modelData
          devices: Audio.sources
        }
      }
    }
  }

  Item {
    width: parent.width
    height: Style.panelSpacing + 36

    WideButton {
      anchors.bottom: parent.bottom
      width: parent.width
      label: "Sound settings"
      onClicked: {
        Quickshell.execDetached(["pavucontrol"])
        panel.requestClose()
      }
    }
  }
}
