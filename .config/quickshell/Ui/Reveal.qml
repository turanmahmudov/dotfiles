import QtQuick
import qs.Commons

// Content that folds away under whatever controls it. The height is switched
// rather than animated: the panel window takes its height from the page, so
// animating it would resize the layer surface on every frame.
Item {
  id: reveal

  property bool open: false
  property int bodySpacing: 4

  default property alias content: body.data

  width: parent ? parent.width : 0
  clip: true
  // Out of its parent column while closed, or the column keeps the spacing
  // around a row of no height.
  visible: height > 0.5
  height: reveal.open ? body.implicitHeight : 0
  opacity: reveal.open ? 1 : 0

  Behavior on opacity {
    NumberAnimation {
      duration: Style.animFast
    }
  }

  Column {
    id: body
    width: parent.width
    spacing: reveal.bodySpacing
  }
}
