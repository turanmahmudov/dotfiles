pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.Services

QtObject {
  id: root

  property bool dnd: false
  property var popups: []
  property int listRevision: 0
  property int ageTick: 0
  property var arrivals: ({})

  readonly property var list: {
    listRevision
    return server.trackedNotifications ? server.trackedNotifications.values : []
  }
  readonly property int unread: list.length

  readonly property var groups: buildGroups(list)

  function resolveGroupKey(n) {
    if (!n)
      return "unknown"
    var entry = String(n.desktopEntry || "").trim()
    if (entry.length)
      return entry.toLowerCase()
    var name = String(n.appName || "").trim()
    if (name.length)
      return name.toLowerCase()
    return String(n.appIcon || n.id || "unknown").toLowerCase()
  }

  function markArrival(n) {
    if (n)
      arrivals[n.id] = Date.now()
  }

  function forgetArrival(n) {
    if (n)
      delete arrivals[n.id]
  }

  function resolveArrival(n) {
    if (!n)
      return 0
    var t = arrivals[n.id]
    return t ? t : 0
  }

  // Notifications that expire on their own, or that the sending app closes,
  // never reach dismiss(), so drop their timestamps whenever the list changes.
  function pruneArrivals() {
    var alive = ({})
    for (var i = 0; i < list.length; i++)
      if (list[i])
        alive[list[i].id] = true
    var next = ({})
    var dropped = false
    for (var id in arrivals) {
      if (alive[id])
        next[id] = arrivals[id]
      else
        dropped = true
    }
    if (dropped)
      arrivals = next
  }

  onListChanged: root.pruneArrivals()

  function formatAge(n) {
    ageTick
    var t = root.resolveArrival(n)
    if (!t)
      return ""
    var seconds = Math.floor((Date.now() - t) / 1000)
    if (seconds < 60)
      return "now"
    var minutes = Math.floor(seconds / 60)
    if (minutes < 60)
      return minutes + "m"
    var hours = Math.floor(minutes / 60)
    if (hours < 24)
      return hours + "h"
    return Math.floor(hours / 24) + "d"
  }

  function buildGroups(items) {
    var map = ({})
    var order = []
    for (var i = 0; i < items.length; i++) {
      var n = items[i]
      if (!n)
        continue
      var key = root.resolveGroupKey(n)
      if (!map[key]) {
        map[key] = {
          "key": key,
          "appName": String(n.appName || n.appIcon || "App"),
          "notifications": [],
          "latest": n,
          "count": 0,
          "arrival": 0,
          "rank": i
        }
        order.push(key)
      }
      var group = map[key]
      group.notifications.push(n)
      group.latest = n
      group.count = group.notifications.length
      group.arrival = Math.max(group.arrival, root.resolveArrival(n))
      group.rank = i
      if (n.appName)
        group.appName = String(n.appName)
    }
    var out = []
    for (var j = 0; j < order.length; j++)
      out.push(map[order[j]])
    out.sort((a, b) => (b.arrival - a.arrival) || (b.rank - a.rank))
    return out
  }

  function toggleDnd() {
    dnd = !dnd
    if (dnd)
      popups = []
  }

  onDndChanged: StateStore.set("notifications.dnd", root.dnd)

  property Connections stateConn: Connections {
    target: StateStore
    function onRestored() {
      root.dnd = StateStore.get("notifications.dnd", root.dnd)
    }
  }

  Component.onCompleted: {
    if (StateStore.ready)
      root.dnd = StateStore.get("notifications.dnd", root.dnd)
  }

  property IpcHandler ipc: IpcHandler {
    target: "notifications"
    function toggleDnd(): string {
      root.toggleDnd()
      return root.dnd ? "on" : "off"
    }
    function status(): string {
      return (root.dnd ? "dnd" : "on") + " " + root.list.length
    }
    function clear(): string {
      root.clearAll()
      return "ok"
    }
  }

  function dismiss(n) {
    removePopup(n)
    forgetArrival(n)
    if (n)
      n.dismiss()
    listRevision = listRevision + 1
  }

  function dismissGroup(group) {
    if (!group || !group.notifications)
      return
    var arr = group.notifications.slice()
    for (var i = 0; i < arr.length; i++)
      root.dismiss(arr[i])
  }

  function clearAll() {
    var l = list.slice()
    popups = []
    arrivals = ({})
    for (var i = 0; i < l.length; i++)
      if (l[i])
        l[i].dismiss()
    listRevision = listRevision + 1
  }

  function addPopup(n) {
    var arr = popups.slice()
    arr.push(n)
    popups = arr
  }

  function removePopup(n) {
    var arr = []
    for (var i = 0; i < popups.length; i++)
      if (popups[i] !== n)
        arr.push(popups[i])
    popups = arr
  }

  function shouldShowPopup() {
    if (dnd)
      return false
    if (Hypr.hasFullscreen())
      return false
    return true
  }

  property Timer ageTicker: Timer {
    interval: 30000
    repeat: true
    running: root.list.length > 0
    onTriggered: root.ageTick = root.ageTick + 1
  }

  property NotificationServer server: NotificationServer {
    keepOnReload: true
    actionsSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    imageSupported: true

    onNotification: (n) => {
      n.tracked = true
      root.markArrival(n)
      root.listRevision = root.listRevision + 1
      if (root.shouldShowPopup())
        root.addPopup(n)
    }
  }
}
