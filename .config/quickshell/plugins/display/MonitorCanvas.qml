import QtQuick
import qs.Commons

Item {
  id: canvas

  readonly property var order: MonitorLayout.resolveOrder()
  readonly property int gap: 6

  readonly property var placement: {
    MonitorLayout.revision
    Monitors.list
    var out = []
    var total = 0
    var tallest = 1
    for (var i = 0; i < canvas.order.length; i++) {
      var m = MonitorLayout.findMonitor(canvas.order[i])
      if (!m || m.disabled)
        continue
      var rotated = m.transform === 1 || m.transform === 3
      var w = Math.round((rotated ? m.height : m.width) / m.scale)
      var h = Math.round((rotated ? m.width : m.height) / m.scale)
      out.push({ "name": m.name, "logicalWidth": w, "logicalHeight": h, "focused": m.focused })
      total += w
      tallest = Math.max(tallest, h)
    }
    return { "items": out, "total": Math.max(1, total), "tallest": tallest }
  }

  readonly property real factor: {
    var p = canvas.placement
    var usableWidth = canvas.width - 24 - canvas.gap * Math.max(0, p.items.length - 1)
    var usableHeight = canvas.height - 24
    return Math.min(usableWidth / p.total, usableHeight / p.tallest)
  }

  implicitHeight: 130

  function resolveOffset(index) {
    var x = 0
    for (var i = 0; i < index; i++)
      x += canvas.placement.items[i].logicalWidth * canvas.factor + canvas.gap
    return x
  }

  Rectangle {
    anchors.fill: parent
    radius: Style.radius
    color: Theme.alpha(Theme.fg, Style.cardAlpha)
    border.color: Theme.alpha(Theme.fg, 0.10)
    border.width: 1
  }

  Item {
    id: stage
    anchors.centerIn: parent
    width: {
      var p = canvas.placement
      return p.total * canvas.factor + canvas.gap * Math.max(0, p.items.length - 1)
    }
    height: canvas.placement.tallest * canvas.factor

    Repeater {
      model: canvas.placement.items

      delegate: Rectangle {
        id: screen
        required property var modelData
        required property int index

        readonly property real homeX: canvas.resolveOffset(index)

        width: modelData.logicalWidth * canvas.factor
        height: modelData.logicalHeight * canvas.factor
        y: stage.height - height
        radius: Style.radiusSmall
        color: dragArea.drag.active
          ? Theme.alpha(Theme.accent, 0.4)
          : (modelData.focused ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.fg, 0.12))
        border.color: modelData.focused ? Theme.accent : Theme.alpha(Theme.fg, 0.3)
        border.width: dragArea.drag.active ? 2 : 1
        z: dragArea.drag.active ? 10 : 0

        Component.onCompleted: x = homeX
        onHomeXChanged: if (!dragArea.drag.active) x = homeX

        Behavior on x {
          enabled: !dragArea.drag.active
          NumberAnimation {
            duration: Style.animFast
            easing.type: Easing.OutCubic
          }
        }

        Column {
          anchors.centerIn: parent
          spacing: 0

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: screen.index + 1
            color: screen.modelData.focused ? Theme.accent : Theme.fgDim
            font.family: Style.fontFamily
            font.pixelSize: Math.max(12, Math.min(24, screen.height * 0.35))
            font.bold: true
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: screen.modelData.name
            color: Theme.fgDim
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
          }
        }

        MouseArea {
          id: dragArea
          anchors.fill: parent
          cursorShape: Qt.SizeHorCursor
          drag.target: screen
          drag.axis: Drag.XAxis
          drag.minimumX: -screen.width
          drag.maximumX: stage.width

          onReleased: {
            var centre = screen.x + screen.width / 2
            var target = 0
            for (var i = 0; i < canvas.placement.items.length; i++) {
              var otherCentre = canvas.resolveOffset(i)
                + canvas.placement.items[i].logicalWidth * canvas.factor / 2
              if (i !== screen.index && otherCentre < centre)
                target = i
            }
            if (target !== screen.index)
              MonitorLayout.moveTo(screen.modelData.name, target)
            else
              screen.x = screen.homeX
          }
        }
      }
    }
  }
}
