import QtQuick
import qs.Commons

Item {
  id: root
  property string name: ""
  property color color: Theme.fg
  property int size: Style.iconSize

  implicitWidth: size
  implicitHeight: size

  onNameChanged: IconCache.request(root.name)
  Component.onCompleted: IconCache.request(root.name)

  Image {
    anchors.fill: parent
    smooth: true
    mipmap: true
    antialiasing: true
    fillMode: Image.PreserveAspectFit
    sourceSize.width: root.size * 4
    sourceSize.height: root.size * 4
    source: IconCache.source(root.name, root.color)
  }
}
