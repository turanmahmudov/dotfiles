import QtQuick
import qs.Commons

// One line of editable text. The value is reported on commit, not per keystroke,
// so a half typed value never reaches the config.
Item {
  id: root

  property string text: ""
  property string placeholder: ""

  signal edited(string value)

  implicitHeight: 32
  height: implicitHeight
  width: parent ? parent.width : implicitWidth

  function commitValue() {
    if (input.text !== root.text)
      root.edited(input.text)
  }

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusSmall
    color: Theme.alpha(Theme.fg, Style.cardAlpha)
    border.width: 1
    border.color: input.activeFocus
      ? Theme.alpha(Theme.accent, 0.5)
      : Theme.alpha(Theme.fg, Style.surfaceBorderAlpha)
  }

  TextInput {
    id: input
    anchors.fill: parent
    anchors.leftMargin: 9
    anchors.rightMargin: 9
    verticalAlignment: TextInput.AlignVCenter
    color: Theme.fg
    font.family: Style.fontFamily
    font.pixelSize: Style.fontCaption
    selectByMouse: true
    clip: true

    onEditingFinished: root.commitValue()
    Keys.onReturnPressed: root.commitValue()
    Component.onCompleted: input.text = root.text
  }

  Text {
    anchors.left: parent.left
    anchors.leftMargin: 9
    anchors.verticalCenter: parent.verticalCenter
    visible: input.text.length === 0 && root.placeholder.length > 0
    text: root.placeholder
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontCaption
  }
}
