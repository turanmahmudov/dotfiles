import QtQuick
import qs.Commons

// Dotted outline that marks out an area while it is edited.
Item {
  id: root

  property color color: Theme.fgDim
  property int radius: Style.radiusSmall

  onColorChanged: canvas.requestPaint()
  onWidthChanged: canvas.requestPaint()
  onHeightChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      if (width < 4 || height < 4)
        return
      ctx.strokeStyle = root.color
      ctx.lineWidth = 1
      ctx.setLineDash([3, 4])
      ctx.beginPath()
      ctx.roundedRect(0.5, 0.5, width - 1, height - 1, root.radius, root.radius)
      ctx.stroke()
    }
  }
}
