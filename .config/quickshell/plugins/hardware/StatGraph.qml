import QtQuick
import qs.Commons

Canvas {
  id: graph

  property var values: []
  property var secondValues: []
  property color lineColor: Theme.accent
  property color secondColor: Theme.accentAlt
  // 0 scales the graph to the largest sample.
  property real maxValue: 100
  property int capacity: SystemStats.historyLength

  width: parent ? parent.width : 0
  height: 34

  onValuesChanged: requestPaint()
  onSecondValuesChanged: requestPaint()
  onLineColorChanged: requestPaint()
  onWidthChanged: requestPaint()

  function resolveScale() {
    if (graph.maxValue > 0)
      return graph.maxValue
    var top = 1
    for (var i = 0; i < graph.values.length; i++)
      top = Math.max(top, graph.values[i])
    for (var j = 0; j < graph.secondValues.length; j++)
      top = Math.max(top, graph.secondValues[j])
    return top * 1.15
  }

  // The Canvas gradient reads an alpha only from a CSS colour string.
  function formatRgba(c, a) {
    return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + a + ")"
  }

  function calculateY(value, scale) {
    return 3 + (graph.height - 4) * (1 - Math.min(1, value / scale))
  }

  function drawSeries(ctx, list, color, scale, fill) {
    if (list.length < 2)
      return
    var step = graph.width / (graph.capacity - 1)
    var x0 = graph.width - (list.length - 1) * step
    ctx.beginPath()
    for (var i = 0; i < list.length; i++) {
      if (i === 0)
        ctx.moveTo(x0, graph.calculateY(list[i], scale))
      else
        ctx.lineTo(x0 + i * step, graph.calculateY(list[i], scale))
    }
    ctx.strokeStyle = color
    ctx.lineWidth = 1.5
    ctx.stroke()
    if (!fill)
      return
    ctx.lineTo(graph.width, graph.height)
    ctx.lineTo(x0, graph.height)
    ctx.closePath()
    var gradient = ctx.createLinearGradient(0, 0, 0, graph.height)
    gradient.addColorStop(0, graph.formatRgba(color, 0.25))
    gradient.addColorStop(1, graph.formatRgba(color, 0))
    ctx.fillStyle = gradient
    ctx.fill()
    ctx.beginPath()
    ctx.arc(graph.width - 2.5, graph.calculateY(list[list.length - 1], scale), 2.5, 0, Math.PI * 2)
    ctx.fillStyle = color
    ctx.fill()
  }

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    ctx.strokeStyle = graph.formatRgba(Theme.fg, 0.07)
    ctx.lineWidth = 1
    ctx.beginPath()
    ctx.moveTo(0, Math.round(graph.height / 2) + 0.5)
    ctx.lineTo(graph.width, Math.round(graph.height / 2) + 0.5)
    ctx.stroke()
    var scale = graph.resolveScale()
    graph.drawSeries(ctx, graph.secondValues, graph.secondColor, scale, false)
    graph.drawSeries(ctx, graph.values, graph.lineColor, scale, true)
  }
}
