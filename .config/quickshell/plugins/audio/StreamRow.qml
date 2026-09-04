import QtQuick
import qs.Commons
import qs.Ui

Column {
  id: stream

  property var node: null
  property var devices: []

  readonly property bool ready: node && node.ready && node.audio
  readonly property var device: Audio.resolveStreamDevice(stream.node)

  property bool listOpen: false

  width: parent ? parent.width : 0
  spacing: Style.spaceTight

  function resolveDeviceLabel(node) {
    if (!node)
      return "No device"
    return node.description || node.nickname || node.name
  }

  // The description repeats the whole controller name, which does not fit on
  // the collapsed row. The nickname is the part that names the device.
  function resolveShortDeviceLabel(node) {
    if (!node)
      return "No device"
    return node.nickname || node.description || node.name
  }

  Rectangle {
    width: parent.width
    height: 32
    radius: Style.radiusSmall
    color: stream.listOpen
      ? Theme.alpha(Theme.accent, headerArea.containsMouse ? 0.24 : 0.16)
      : Theme.alpha(Theme.fg, headerArea.containsMouse ? Style.cardHoverAlpha : Style.cardAlpha)

    Behavior on color {
      ColorAnimation {
        duration: Style.animFast
      }
    }

    Icon {
      id: chevron
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      name: "chevron-right"
      color: stream.listOpen ? Theme.accent : Theme.fgDim
      size: Style.iconTiny
      rotation: stream.listOpen ? 90 : 0

      Behavior on rotation {
        NumberAnimation {
          duration: Style.anim
          easing.type: Easing.OutCubic
        }
      }
    }

    Text {
      id: appLabel
      anchors.left: chevron.right
      anchors.leftMargin: 8
      anchors.right: deviceLabel.left
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
      text: Audio.resolveStreamLabel(stream.node)
      color: stream.listOpen ? Theme.accent : Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontBody
    }

    Text {
      id: deviceLabel
      anchors.right: parent.right
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(implicitWidth, stream.width * 0.5)
      horizontalAlignment: Text.AlignRight
      elide: Text.ElideRight
      text: stream.resolveShortDeviceLabel(stream.device)
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontCaption
      opacity: stream.listOpen ? 0 : 1

      Behavior on opacity {
        NumberAnimation {
          duration: Style.animFast
        }
      }
    }

    MouseArea {
      id: headerArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: stream.listOpen = !stream.listOpen
    }
  }

  Item {
    width: parent.width
    height: 24
    visible: stream.ready

    Icon {
      id: volIcon
      anchors.left: parent.left
      anchors.leftMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      name: Icons.volume(stream.ready && stream.node.audio.muted, stream.ready ? stream.node.audio.volume : 0)
      color: (stream.ready && stream.node.audio.muted) ? Theme.fgDim : Theme.fg
      size: Style.iconSmall

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (stream.ready) stream.node.audio.muted = !stream.node.audio.muted
      }
    }

    Text {
      id: volValue
      anchors.right: parent.right
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      width: 34
      horizontalAlignment: Text.AlignRight
      text: Math.round((stream.ready ? stream.node.audio.volume : 0) * 100) + "%"
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontMicro
    }

    Slider {
      anchors.left: volIcon.right
      anchors.right: volValue.left
      anchors.leftMargin: 10
      anchors.rightMargin: 9
      anchors.verticalCenter: parent.verticalCenter
      value: stream.ready ? stream.node.audio.volume : 0
      onMoved: (v) => {
        if (stream.ready)
          stream.node.audio.volume = Math.max(0, Math.min(1, v))
      }
    }
  }

  Item {
    id: deviceClip
    width: parent.width
    clip: true
    visible: height > 0.5
    height: stream.listOpen ? deviceColumn.implicitHeight : 0
    opacity: stream.listOpen ? 1 : 0

    Behavior on opacity {
      NumberAnimation {
        duration: Style.animFast
      }
    }

    Column {
      id: deviceColumn
      width: parent.width
      spacing: Style.spaceTight

    Repeater {
      model: stream.devices

      delegate: Rectangle {
        id: deviceRow
        required property var modelData
        readonly property bool active: stream.device && modelData && stream.device.id === modelData.id
        width: parent.width
        height: 28
        radius: Style.radiusSmall
        color: deviceRow.active
          ? Theme.alpha(Theme.accent, deviceArea.containsMouse ? Style.cardActiveHoverAlpha : Style.cardActiveAlpha)
          : Theme.alpha(Theme.fg, deviceArea.containsMouse ? Style.cardHoverAlpha : Style.cardAlpha)

        Text {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: 20
          anchors.rightMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          elide: Text.ElideRight
          text: stream.resolveDeviceLabel(deviceRow.modelData)
          color: deviceRow.active ? Theme.accent : Theme.fg
          font.family: Style.fontFamily
          font.pixelSize: Style.fontCaption
        }

        MouseArea {
          id: deviceArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            Audio.moveStream(stream.node, deviceRow.modelData)
            stream.listOpen = false
          }
        }
      }
    }
    }
  }
}
