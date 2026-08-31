import QtQuick
import qs.Commons

// Names the block under it. The padding keeps it off the block above and holds
// it close to its own, which the even column spacing alone does not do.
Text {
  color: Theme.fgDim
  font.family: Style.fontFamily
  font.pixelSize: Style.fontSize - 2
  topPadding: 18
  bottomPadding: 0
}
