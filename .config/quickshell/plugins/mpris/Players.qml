pragma Singleton
import QtQuick
import Quickshell.Services.Mpris

QtObject {
  id: root

  readonly property var list: Mpris.players ? Mpris.players.values : []

  readonly property var aliases: ({
    "Mozilla Firefox": "Firefox",
    "chromium": "Chromium"
  })

  function identityOf(player) {
    if (!player)
      return ""
    var id = String(player.identity || "")
    return root.aliases[id] || id
  }

  function pickActive(list) {
    var playing = null
    var any = null
    var arr = list || root.list
    for (var i = 0; i < arr.length; i++) {
      var p = arr[i]
      if (!p)
        continue
      if (!any)
        any = p
      if (p.playbackState === MprisPlaybackState.Playing) {
        playing = p
        break
      }
    }
    return playing || any
  }

  function artUrl(player) {
    if (!player)
      return ""
    if (player.trackArtUrl)
      return player.trackArtUrl
    var url = ""
    try {
      url = String(player.metadata["xesam:url"] || "")
    } catch (e) {
      url = ""
    }
    if (url.indexOf("https://www.youtube.com/watch") === 0 || url.indexOf("https://youtube.com/watch") === 0
        || url.indexOf("https://youtu.be/") === 0) {
      var id = ""
      var m = url.match(/[?&]v=([\w-]{11})/)
      if (m)
        id = m[1]
      else {
        m = url.match(/youtu\.be\/([\w-]{11})/)
        if (m)
          id = m[1]
      }
      if (id)
        return "https://img.youtube.com/vi/" + id + "/hqdefault.jpg"
    }
    return ""
  }
}
