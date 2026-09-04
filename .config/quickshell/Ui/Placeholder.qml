import QtQuick
import qs.Commons

// Stands in for a list that has nothing to show yet, so a panel never opens on
// blank space. The spinner marks work in progress rather than an empty result.
Item {
  id: root

  property string text: ""
  property bool busy: false

  width: parent ? parent.width : implicitWidth
  implicitHeight: Style.rowHeight
  height: implicitHeight

  Row {
    anchors.centerIn: parent
    spacing: Style.space

    Icon {
      id: spinner
      anchors.verticalCenter: parent.verticalCenter
      visible: root.busy
      name: "refresh-cw"
      color: Theme.fgDim
      size: Style.iconTiny
      transformOrigin: Item.Center

      RotationAnimator on rotation {
        running: root.busy
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 900
        onRunningChanged: if (!running) spinner.rotation = 0
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.text
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontCaption
    }
  }
}
