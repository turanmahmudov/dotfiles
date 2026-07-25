import QtQuick
import qs.Commons
import qs.Ui

Popup {
  id: panel
  pluginId: "shell.clock"
  cardWidth: 260

  readonly property date today: new Date()
  property int viewYear: today.getFullYear()
  property int viewMonth: today.getMonth()
  readonly property bool viewingCurrentMonth: viewYear === today.getFullYear() && viewMonth === today.getMonth()
  readonly property var cells: computeCells(viewYear, viewMonth)

  function shiftMonth(delta) {
    var d = new Date(viewYear, viewMonth + delta, 1)
    viewYear = d.getFullYear()
    viewMonth = d.getMonth()
  }

  function goToday() {
    viewYear = today.getFullYear()
    viewMonth = today.getMonth()
  }

  function computeCells(y, m) {
    var first = new Date(y, m, 1)
    var startDow = (first.getDay() + 6) % 7
    var dim = new Date(y, m + 1, 0).getDate()
    var prevDim = new Date(y, m, 0).getDate()
    var arr = []
    for (var i = startDow - 1; i >= 0; i--)
      arr.push({ "day": prevDim - i, "current": false })
    for (var d = 1; d <= dim; d++)
      arr.push({ "day": d, "current": true })
    var rem = 42 - arr.length
    for (var t = 1; t <= rem; t++)
      arr.push({ "day": t, "current": false })
    return arr
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: Qt.formatDate(panel.today, "dddd, d MMMM")
    color: Theme.accent
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize
    font.bold: true
  }

  Item {
    width: parent.width
    height: 26

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
      font.pixelSize: Style.fontSize
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
    anchors.horizontalCenter: parent.horizontalCenter
    implicitWidth: gridsCol.implicitWidth
    implicitHeight: gridsCol.implicitHeight

    Column {
      id: gridsCol
      spacing: 4

      Grid {
        columns: 7
        spacing: 4

        Repeater {
          model: 7
          Text {
            required property int index
            width: 30
            horizontalAlignment: Text.AlignHCenter
            text: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"][index]
            color: Theme.accent
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize - 2
            font.bold: true
          }
        }
      }

      Grid {
        columns: 7
        spacing: 4

        Repeater {
          model: panel.cells

          Item {
            id: cell
            required property var modelData
            readonly property bool isToday: modelData.current && panel.viewingCurrentMonth && modelData.day === panel.today.getDate()
            width: 30
            height: 26

            Rectangle {
              anchors.centerIn: parent
              width: 28
              height: 24
              radius: Style.radiusSmall
              visible: cell.isToday
              color: Theme.accent
            }

            Text {
              anchors.centerIn: parent
              text: cell.modelData.day
              color: cell.isToday ? Theme.bg : (cell.modelData.current ? Theme.fg : Theme.fgDim)
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSize - 1
              font.bold: cell.isToday
            }
          }
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      onWheel: (e) => panel.shiftMonth(e.angleDelta.y > 0 ? -1 : 1)
    }
  }
}
