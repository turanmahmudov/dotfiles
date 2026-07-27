import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "Now playing"

  readonly property var players: Mpris.players ? Mpris.players.values : []
  property var selectedPlayer: null

  readonly property var player: (selectedPlayer && players.indexOf(selectedPlayer) >= 0) ? selectedPlayer : pickPlayer()
  readonly property bool hasPlayer: player !== null
  readonly property bool playing: hasPlayer && player.playbackState === MprisPlaybackState.Playing
  readonly property bool canSeek: hasPlayer && player.canSeek && player.positionSupported && player.lengthSupported && player.length > 0

  property real posSec: 0

  function pickPlayer() {
    return Players.pickActive(players)
  }

  function formatTime(sec) {
    if (!sec || sec < 0 || !isFinite(sec))
      return "0:00"
    var total = Math.floor(sec)
    var m = Math.floor(total / 60)
    var s = total % 60
    return m + ":" + (s < 10 ? "0" + s : s)
  }

  function cycleLoop() {
    if (!hasPlayer)
      return
    var s = player.loopState
    player.loopState = s === MprisLoopState.None ? MprisLoopState.Playlist : (s === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None)
  }

  function syncStateFromPlayer() {
    if (!hasPlayer) {
      posSec = 0
      return
    }
    posSec = player.position
    if (canSeek)
      seekSlider.value = player.length > 0 ? (posSec / player.length) : 0
    if (player.volumeSupported)
      volumeSlider.value = player.volume
  }

  onPlayerChanged: syncStateFromPlayer()

  Timer {
    interval: 500
    repeat: true
    running: panel.visible && panel.hasPlayer
    triggeredOnStart: true
    onTriggered: panel.syncStateFromPlayer()
  }

  Text {
    visible: !panel.hasPlayer
    width: parent.width
    text: "No media playing"
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize
  }

  Item {
    visible: panel.hasPlayer
    width: parent.width
    height: 56

    Rectangle {
      id: artBox
      width: 56
      height: 56
      radius: Style.radiusSmall
      color: Theme.alpha(Theme.fg, 0.08)
      anchors.verticalCenter: parent.verticalCenter

      Icon {
        anchors.centerIn: parent
        visible: art.status !== Image.Ready
        name: "music"
        color: Theme.fgDim
        size: 22
      }

      Image {
        id: art
        anchors.fill: parent
        source: panel.hasPlayer ? Players.artUrl(panel.player) : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 112
        sourceSize.height: 112
        smooth: true
        mipmap: true
        cache: false
      }
    }

    Column {
      anchors.left: artBox.right
      anchors.leftMargin: 12
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 3

      Text {
        width: parent.width
        elide: Text.ElideRight
        text: panel.hasPlayer ? (panel.player.trackTitle || "Unknown title") : ""
        color: Theme.fg
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize
        font.bold: true
      }

      Text {
        width: parent.width
        elide: Text.ElideRight
        visible: text.length > 0
        text: {
          if (!panel.hasPlayer)
            return ""
          var artist = panel.player.trackArtist || ""
          var album = panel.player.trackAlbum || ""
          return album ? (artist ? (artist + " · " + album) : album) : artist
        }
        color: Theme.fgDim
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize - 2
      }
    }
  }

  Item {
    visible: panel.canSeek
    width: parent.width
    height: 18

    Text {
      id: curTime
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: panel.formatTime(panel.posSec)
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 3
    }

    Text {
      id: totalTime
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: panel.hasPlayer ? panel.formatTime(panel.player.length) : "0:00"
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 3
    }

    Slider {
      id: seekSlider
      anchors.left: curTime.right
      anchors.right: totalTime.left
      anchors.leftMargin: 8
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      onMoved: (v) => {
        if (!panel.hasPlayer)
          return
        var target = v * panel.player.length
        panel.posSec = target
        panel.player.position = target
      }
    }
  }

  Item {
    visible: panel.hasPlayer
    width: parent.width
    height: 34

    Row {
      anchors.centerIn: parent
      spacing: 16

      IconButton {
        anchors.verticalCenter: parent.verticalCenter
        name: "shuffle"
        iconSize: 17
        visible: panel.hasPlayer && panel.player.shuffleSupported
        color: (panel.hasPlayer && panel.player.shuffle) ? Theme.accent : (hovered ? Theme.fg : Theme.fgDim)
        onClicked: if (panel.hasPlayer) panel.player.shuffle = !panel.player.shuffle
      }

      IconButton {
        anchors.verticalCenter: parent.verticalCenter
        name: "skip-back"
        iconSize: 20
        enabled: panel.hasPlayer && panel.player.canGoPrevious
        color: !enabled ? Theme.alpha(Theme.fg, 0.3) : (hovered ? Theme.accent : Theme.fg)
        onClicked: if (panel.hasPlayer) panel.player.previous()
      }

      IconButton {
        anchors.verticalCenter: parent.verticalCenter
        name: panel.playing ? "pause" : "play"
        iconSize: 26
        enabled: panel.hasPlayer && panel.player.canTogglePlaying
        color: hovered ? Theme.accent : Theme.fg
        onClicked: if (panel.hasPlayer) panel.player.togglePlaying()
      }

      IconButton {
        anchors.verticalCenter: parent.verticalCenter
        name: "skip-forward"
        iconSize: 20
        enabled: panel.hasPlayer && panel.player.canGoNext
        color: !enabled ? Theme.alpha(Theme.fg, 0.3) : (hovered ? Theme.accent : Theme.fg)
        onClicked: if (panel.hasPlayer) panel.player.next()
      }

      IconButton {
        anchors.verticalCenter: parent.verticalCenter
        name: (panel.hasPlayer && panel.player.loopState === MprisLoopState.Track) ? "repeat-1" : "repeat"
        iconSize: 17
        color: (panel.hasPlayer && panel.player.loopState !== MprisLoopState.None) ? Theme.accent : (hovered ? Theme.fg : Theme.fgDim)
        onClicked: panel.cycleLoop()
      }
    }
  }

  Item {
    visible: panel.hasPlayer && panel.player.volumeSupported
    width: parent.width
    height: 18

    Icon {
      id: volIcon
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      name: "volume-2"
      color: Theme.fg
      size: 16
    }

    Slider {
      id: volumeSlider
      anchors.left: volIcon.right
      anchors.leftMargin: 10
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      onMoved: (v) => { if (panel.hasPlayer) panel.player.volume = v }
    }
  }

  Flow {
    visible: panel.players.length > 1
    width: parent.width
    spacing: 6

    Repeater {
      model: panel.players

      delegate: Rectangle {
        id: pill
        required property var modelData
        readonly property bool active: modelData === panel.player
        height: 26
        width: pillText.implicitWidth + 20
        radius: Style.radiusSmall
        color: pill.active ? Theme.alpha(Theme.accent, pillArea.containsMouse ? 0.28 : 0.2) : Theme.alpha(Theme.fg, pillArea.containsMouse ? 0.12 : 0.06)

        Text {
          id: pillText
          anchors.centerIn: parent
          text: pill.modelData ? (pill.modelData.identity || "Player") : "Player"
          color: pill.active ? Theme.accent : Theme.fg
          font.family: Style.fontFamily
          font.pixelSize: Style.fontSize - 2
        }

        MouseArea {
          id: pillArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: panel.selectedPlayer = pill.modelData
        }
      }
    }
  }
}
