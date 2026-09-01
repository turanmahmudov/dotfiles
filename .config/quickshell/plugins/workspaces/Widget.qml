import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Services
import qs.Ui

BarItem {
  id: root
  interactive: false
  horizontalPadding: Style.paddingH
  implicitHeight: Style.barHeight - 6

  readonly property bool showWindowIcons: !(settings && settings.showWindowIcons === false)
  readonly property string monName: screen ? screen.name : ""
  readonly property var monitor: Hypr.monitorFor(screen)
  readonly property string activeSpecialName: Hypr.activeSpecialName(monitor)
  readonly property bool onSpecial: activeSpecialName.length > 0

  readonly property int desktopEntryCount: DesktopEntries.applications ? DesktopEntries.applications.values.length : 0
  readonly property int hyprRev: Hypr.revision

  readonly property var windowsByWs: {
    hyprRev
    desktopEntryCount
    return Hypr.windowsByWorkspace()
  }
  readonly property var urgentWsIds: {
    hyprRev
    return Hypr.urgentWorkspaceIds()
  }
  readonly property var items: {
    hyprRev
    desktopEntryCount
    monName
    monitorNames
    return computeItems()
  }

  readonly property var monitorNames: {
    hyprRev
    return collectMonitorNames()
  }

  function collectMonitorNames() {
    var mons = Hypr.monitors ? Hypr.monitors.values : []
    var names = ({})
    for (var i = 0; i < mons.length; i++)
      if (mons[i] && mons[i].name)
        names[String(mons[i].name)] = true
    return names
  }

  // A monitor that is off keeps its persistent workspaces in the settings, so
  // one connected bar adopts them and the user still sees every workspace.
  function resolveOrphanHost(persistent) {
    var active = root.monitorNames
    var configured = Object.keys(persistent).sort()
    for (var i = 0; i < configured.length; i++)
      if (active[configured[i]])
        return configured[i]
    var connected = Object.keys(active).sort()
    return connected.length > 0 ? connected[0] : ""
  }

  function persistentFor(mon) {
    var p = (settings && settings.persistent) ? settings.persistent : ({})
    var own = p[mon] || []
    if (resolveOrphanHost(p) !== mon)
      return own
    var out = own.slice()
    var active = root.monitorNames
    for (var key in p)
      if (key !== mon && !active[key])
        out = out.concat(p[key])
    return out
  }

  function labelFor(item) {
    if (item.special)
      return item.key && item.key.length > 0 ? item.key : "special"
    return String(item.id)
  }

  // Icon resolution runs per window on every compositor event, so results are
  // memoized per class and dropped when the desktop entry set changes.
  property var iconByClass: ({})

  onDesktopEntryCountChanged: root.iconByClass = ({})

  function resolveWinIcon(cls) {
    var cached = iconByClass[cls]
    if (cached !== undefined)
      return cached
    var resolved = root.lookupWinIcon(cls)
    iconByClass[cls] = resolved
    return resolved
  }

  function lookupWinIcon(cls) {
    var entry = DesktopEntries.heuristicLookup(cls)
    if (!entry && cls.indexOf(" ") >= 0)
      entry = DesktopEntries.heuristicLookup(cls.replace(/ /g, "-"))
    if (entry && entry.icon && entry.icon.length > 0) {
      if (entry.icon.charAt(0) === "/")
        return "file://" + entry.icon
      var p = Quickshell.iconPath(entry.icon, true)
      if (p && p.length > 0)
        return p
    }
    return Quickshell.iconPath(cls, true)
  }

  function windowsFor(wsId) {
    var m = windowsByWs[String(wsId)] || ({})
    var out = []
    for (var cls in m) {
      var ic = root.resolveWinIcon(cls)
      out.push({ "icon": ic || "", "placeholder": !ic || ic.length === 0 })
    }
    return out
  }

  function computeItems() {
    var all = Hyprland.workspaces ? Hyprland.workspaces.values : []
    var normal = ({})
    var specials = []
    for (var i = 0; i < all.length; i++) {
      var w = all[i]
      if (!w)
        continue
      var name = w.name ? String(w.name) : ""
      if (Hypr.isSpecialName(name) || w.id < 0) {
        if (w.monitor && w.monitor.name === root.monName)
          specials.push(w)
        continue
      }
      if (w.monitor && w.monitor.name === root.monName)
        normal[w.id] = w
    }

    var ids = ({})
    for (var k in normal)
      ids[k] = true
    var pers = persistentFor(root.monName)
    for (var j = 0; j < pers.length; j++)
      ids[pers[j]] = true

    var list = Object.keys(ids).map(function (x) {
      return parseInt(x)
    }).sort(function (a, b) {
      return a - b
    })

    var out = list.map(function (id) {
      return {
        "id": id,
        "name": normal[id] ? String(normal[id].name || id) : String(id),
        "ws": normal[id] || null,
        "special": false,
        "key": "",
        "windows": root.windowsFor(id)
      }
    })

    specials.sort(function (a, b) {
      return String(a.name || "").localeCompare(String(b.name || ""))
    })
    for (var s = 0; s < specials.length; s++) {
      var sw = specials[s]
      var sn = String(sw.name || "")
      out.push({
        "id": sw.id,
        "name": sn,
        "ws": sw,
        "special": true,
        "key": Hypr.specialKey(sn),
        "windows": root.windowsFor(sw.id)
      })
    }
    return out
  }

  function activate(item) {
    if (item.special) {
      Hypr.toggleSpecialWorkspace(item.key || "special")
      return
    }
    Hypr.focusWorkspace(item.id)
  }

  Row {
    id: row
    spacing: 8

    Repeater {
      model: root.items

      delegate: Rectangle {
        id: wsBtn
        required property var modelData
        readonly property bool focused: modelData.special
          ? (root.activeSpecialName === modelData.name)
          : (!root.onSpecial && !!(modelData.ws && modelData.ws.focused))
        readonly property bool occupied: modelData.ws !== null
        readonly property bool urgent: !focused && !!root.urgentWsIds[modelData.id]
        implicitWidth: content.implicitWidth + 18
        implicitHeight: Style.barHeight - 10
        radius: Style.radiusSmall
        color: focused ? Theme.fg : (urgent ? Theme.urgent : "transparent")
        border.width: modelData.special && !focused ? 1 : 0
        border.color: Theme.alpha(Theme.fg, 0.35)
        opacity: (!modelData.special && root.onSpecial) ? 0.55 : 1

        Row {
          id: content
          anchors.centerIn: parent
          spacing: 5

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.labelFor(wsBtn.modelData)
            color: (wsBtn.focused || wsBtn.urgent) ? Theme.bg : (wsBtn.occupied ? Theme.fg : Theme.fgDim)
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
            font.bold: wsBtn.focused
          }

          Repeater {
            model: root.showWindowIcons ? wsBtn.modelData.windows : []

            delegate: Item {
              id: winIcon
              required property var modelData
              anchors.verticalCenter: parent.verticalCenter
              width: 17
              height: 17

              Image {
                anchors.fill: parent
                visible: !winIcon.modelData.placeholder
                sourceSize.width: 128
                sourceSize.height: 128
                fillMode: Image.PreserveAspectFit
                source: winIcon.modelData.icon
                smooth: true
                mipmap: true
              }

              Icon {
                anchors.fill: parent
                visible: winIcon.modelData.placeholder
                name: "app-window"
                size: 17
                color: (wsBtn.focused || wsBtn.urgent) ? Theme.bg : Theme.fg
              }
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.activate(wsBtn.modelData)
        }
      }
    }
  }

  WheelHandler {
    onWheel: (e) => {
      if (root.onSpecial)
        return
      Hypr.focusWorkspace(e.angleDelta.y > 0 ? "e+1" : "e-1")
    }
  }
}
