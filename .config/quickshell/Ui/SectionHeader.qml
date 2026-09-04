import QtQuick
import qs.Commons

// Names the block under it. The padding keeps it off the block above and holds
// it close to its own, which the even column spacing alone does not do. A
// header that leads a panel has nothing to be kept off, so it drops the gap.
Text {
  id: header

  property bool isFirst: parent && parent.children.length > 0 && parent.children[0] === header

  color: Theme.fgDim
  font.family: Style.fontFamily
  font.pixelSize: Style.fontBody
  topPadding: header.isFirst ? 0 : 18
  bottomPadding: 0
}
