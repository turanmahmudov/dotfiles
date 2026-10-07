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
  height: body.implicitHeight
  opacity: 1

  property bool ready: false
  Component.onCompleted: reveal.ready = true

  states: State {
    name: "closed"
    when: !reveal.open

    PropertyChanges {
      reveal.height: 0
      reveal.opacity: 0
    }
  }

  transitions: [
    Transition {
      to: "closed"
      enabled: reveal.ready

      SequentialAnimation {
        NumberAnimation {
          property: "opacity"
          duration: Style.animFast
          easing.type: Easing.InCubic
        }
        PropertyAction {
          property: "height"
        }
      }
    },
    Transition {
      from: "closed"
      enabled: reveal.ready

      SequentialAnimation {
        PropertyAction {
          property: "height"
        }
        NumberAnimation {
          property: "opacity"
          duration: Style.animFast
          easing.type: Easing.OutCubic
        }
      }
    }
  ]

  Column {
    id: body
    width: parent.width
    spacing: reveal.bodySpacing
  }
}
