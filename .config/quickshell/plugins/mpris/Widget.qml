import QtQuick
import Quickshell.Services.Mpris
import qs.Commons
import qs.Ui

BarItem {
  id: root

  readonly property var playerList: Mpris.players ? Mpris.players.values : []
  readonly property var player: Players.pickActive(playerList)
  readonly property bool hasPlayer: !!player
  readonly property bool playing: hasPlayer && player.playbackState === MprisPlaybackState.Playing
  readonly property string ident: hasPlayer ? String(Players.identityOf(player)).toLowerCase() : ""

  shown: hasPlayer
  tooltipText: hasPlayer
    ? (String(player.trackTitle || "") + (player.trackArtist ? ("  —  " + player.trackArtist) : ""))
    : ""
  onClicked: openPanel()
  onRightClicked: if (player) player.togglePlaying()
  onScrolledUp: if (player) player.next()
  onScrolledDown: if (player) player.previous()

  Icon {
    name: root.playing ? "music" : "play"
    color: root.ident.indexOf("spotify") >= 0
      ? Theme.accentActive
      : (root.ident.indexOf("firefox") >= 0 ? Theme.urgent : Theme.fg)
  }
}
