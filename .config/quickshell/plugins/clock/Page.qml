import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

PanelPage {
  id: panel

  readonly property date today: clock.date
  property int viewYear: today.getFullYear()
  property int viewMonth: today.getMonth()
  property date selectedDay: new Date(today.getFullYear(), today.getMonth(), today.getDate())
  readonly property var cells: computeCells(viewYear, viewMonth)

  // Day key "YYYY-MM-DD" to the list of events on that day.
  property var eventsByDay: ({})
  property bool calendarFailed: false

  readonly property real cellWidth: (width - Style.spaceHair * 6) / 7

  SystemClock {
    id: clock
    precision: SystemClock.Hours
  }

  function shiftMonth(delta) {
    var d = new Date(viewYear, viewMonth + delta, 1)
    viewYear = d.getFullYear()
    viewMonth = d.getMonth()
  }

  function goToday() {
    viewYear = today.getFullYear()
    viewMonth = today.getMonth()
    selectedDay = new Date(today.getFullYear(), today.getMonth(), today.getDate())
  }

  function formatKey(d) {
    function pad(n) {
      return n < 10 ? "0" + n : "" + n
    }
    return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
  }

  function isSameDay(a, b) {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
  }

  function computeCells(y, m) {
    var first = new Date(y, m, 1)
    var start = new Date(y, m, 1 - (first.getDay() + 6) % 7)
    var arr = []
    for (var i = 0; i < 42; i++) {
      var d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
      arr.push({ "date": d, "day": d.getDate(), "current": d.getMonth() === m, "weekend": i % 7 >= 5 })
    }
    return arr
  }

  function loadEvents() {
    eventsProc.running = false
    eventsProc.command = [Quickshell.env("HOME") + "/.local/bin/calendar-events", formatKey(cells[0].date), formatKey(cells[41].date)]
    eventsProc.running = true
  }

  function parseEvents(text) {
    if (text.trim().length === 0)
      return
    var byDay = {}
    try {
      var list = JSON.parse(text)
      for (var i = 0; i < list.length; i++) {
        for (var j = 0; j < list[i].days.length; j++) {
          var key = list[i].days[j]
          if (!byDay[key])
            byDay[key] = []
          byDay[key].push(list[i])
        }
      }
    } catch (e) {
      console.warn("clock: failed to parse calendar-events output:", e)
    }
    panel.eventsByDay = byDay
  }

  onCellsChanged: loadEvents()
  Component.onCompleted: loadEvents()

  Process {
    id: eventsProc
    stdout: StdioCollector {
      onStreamFinished: panel.parseEvents(text)
    }
    onExited: (code) => panel.calendarFailed = code !== 0
  }

  Item {
    width: parent.width
    height: 30

    IconButton {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      name: "chevron-left"
      iconSize: 18
      color: hovered ? Theme.accent : Theme.fg
      onClicked: panel.shiftMonth(-1)
    }

    Text {
      anchors.centerIn: parent
      text: Qt.formatDate(new Date(panel.viewYear, panel.viewMonth, 1), "MMMM yyyy")
      color: titleArea.containsMouse ? Theme.accent : Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontTitle
      font.bold: true

      MouseArea {
        id: titleArea
        anchors.fill: parent
        anchors.margins: -8
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: panel.goToday()
      }
    }

    IconButton {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      name: "chevron-right"
      iconSize: 18
      color: hovered ? Theme.accent : Theme.fg
      onClicked: panel.shiftMonth(1)
    }
  }

  Item {
    width: parent.width
    implicitHeight: grid.implicitHeight

    Grid {
      id: grid
      columns: 7
      columnSpacing: Style.spaceHair
      rowSpacing: Style.spaceHair

      Repeater {
        model: 7

        Text {
          required property int index
          width: panel.cellWidth
          height: 22
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          text: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"][index]
          color: Theme.accent
          font.family: Style.fontFamily
          font.pixelSize: Style.fontCaption
          font.bold: true
        }
      }

      Repeater {
        model: panel.cells

        Item {
          id: cell
          required property var modelData
          readonly property var info: modelData
          readonly property bool isToday: panel.isSameDay(info.date, panel.today)
          readonly property bool isSelected: panel.isSameDay(info.date, panel.selectedDay)
          readonly property var dayEvents: panel.eventsByDay[panel.formatKey(info.date)] || []
          width: panel.cellWidth
          height: 32

          Rectangle {
            anchors.fill: parent
            radius: Style.radiusSmall
            color: cell.isToday ? Theme.accent
              : (cell.isSelected ? Theme.alpha(Theme.accent, Style.cardActiveAlpha)
              : (dayArea.containsMouse ? Theme.alpha(Theme.fg, Style.cardHoverAlpha) : "transparent"))
          }

          Text {
            anchors.centerIn: parent
            text: cell.info.day
            color: cell.isToday ? Theme.bg
              : (!cell.info.current ? Theme.surface
              : (cell.info.weekend ? Theme.fgDim : Theme.fg))
            font.family: Style.fontFamily
            font.pixelSize: Style.fontBody
            font.bold: cell.isToday
          }

          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            width: 4
            height: 4
            radius: 2
            visible: cell.dayEvents.length > 0
            color: cell.isToday ? Theme.bg : (cell.dayEvents.length > 0 && cell.dayEvents[0].color ? cell.dayEvents[0].color : Theme.urgent)
          }

          MouseArea {
            id: dayArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              panel.selectedDay = cell.info.date
              if (!cell.info.current)
                panel.shiftMonth(cell.info.date < new Date(panel.viewYear, panel.viewMonth, 1) ? -1 : 1)
            }
          }
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.NoButton
      onWheel: (e) => panel.shiftMonth(e.angleDelta.y > 0 ? -1 : 1)
    }
  }

  SectionHeader {
    text: (panel.isSameDay(panel.selectedDay, panel.today) ? "Today  ·  " : "") + Qt.formatDate(panel.selectedDay, "dddd d MMMM")
  }

  Text {
    readonly property var dayEvents: panel.eventsByDay[panel.formatKey(panel.selectedDay)] || []
    width: parent.width
    visible: dayEvents.length === 0
    text: panel.calendarFailed ? "Calendar service unavailable" : "No events"
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontBody
  }

  Repeater {
    model: panel.eventsByDay[panel.formatKey(panel.selectedDay)] || []

    Rectangle {
      required property var modelData
      width: parent.width
      height: Style.rowHeight
      radius: Style.radiusSmall
      color: Theme.alpha(Theme.fg, Style.cardAlpha)
      border.width: 1
      border.color: Theme.alpha(Theme.fg, Style.cardBorderAlpha)

      Rectangle {
        x: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height - 14
        radius: 1.5
        color: modelData.color ? modelData.color : Theme.accent
      }

      Text {
        id: timeLabel
        x: 20
        width: 52
        anchors.verticalCenter: parent.verticalCenter
        text: modelData.allDay ? "all day" : modelData.start
        color: Theme.fgDim
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
      }

      Text {
        anchors.left: timeLabel.right
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: modelData.title
        color: Theme.fg
        font.family: Style.fontFamily
        font.pixelSize: Style.fontBody
      }
    }
  }
}
