import QtQuick
import qs.Commons

// One field of a settings form, drawn from a descriptor. The host owns where the
// value comes from and where it goes; this only renders and reports an edit.
Column {
  id: root

  property var field: ({})
  property var value: undefined

  signal edited(var value)

  readonly property string type: field.type ? String(field.type) : "text"
  readonly property string label: field.label ? field.label : field.key
  readonly property real minimum: field.min !== undefined ? Number(field.min) : 0
  readonly property real maximum: field.max !== undefined ? Number(field.max) : 1
  readonly property real stepSize: field.step !== undefined ? Number(field.step) : 0.01
  readonly property real span: Math.max(0.0001, root.maximum - root.minimum)
  readonly property bool changedFromDefault: field.default !== undefined
    && String(root.value) !== String(field.default)

  // Rounds to the declared step, so a slider cannot report 0.15000000000000002.
  function quantize(fraction) {
    var raw = root.minimum + fraction * root.span
    var steps = Math.round((raw - root.minimum) / root.stepSize)
    return Math.round((root.minimum + steps * root.stepSize) * 10000) / 10000
  }

  spacing: Style.spaceTight

  Item {
    width: parent.width
    height: 22

    Text {
      anchors.left: parent.left
      anchors.right: resetButton.left
      anchors.rightMargin: 6
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
      text: root.label
      color: Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontCaption
      font.bold: true
    }

    // Only offered once the value differs from the declared default, so a form of
    // untouched fields stays quiet.
    IconButton {
      id: resetButton
      anchors.right: boolSwitch.visible ? boolSwitch.left : parent.right
      anchors.rightMargin: boolSwitch.visible ? 8 : 0
      anchors.verticalCenter: parent.verticalCenter
      implicitHeight: 20
      iconSize: 11
      visible: root.changedFromDefault
      name: "rotate-cw"
      color: hovered ? Theme.accent : Theme.fgDim
      tooltipText: "Back to " + root.field.default
      onClicked: root.edited(root.field.default)
    }

    Switch {
      id: boolSwitch
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      visible: root.type === "bool"
      checked: root.value !== false
      onToggled: root.edited(!checked)
    }
  }

  TextField {
    width: parent.width
    visible: root.type === "text"
    text: root.value !== undefined ? String(root.value) : ""
    placeholder: root.field.default !== undefined ? String(root.field.default) : ""
    onEdited: (text) => root.edited(text)
  }

  Item {
    width: parent.width
    height: root.type === "number" ? 26 : 0
    visible: root.type === "number"

    Slider {
      anchors.left: parent.left
      anchors.right: numberValue.left
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      wheelEnabled: false
      stepSize: root.stepSize / root.span
      value: (Number(root.value) - root.minimum) / root.span
      onMoved: (fraction) => root.edited(root.quantize(fraction))
    }

    Text {
      id: numberValue
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      horizontalAlignment: Text.AlignRight
      width: 44
      text: root.value !== undefined ? String(root.value) : ""
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontCaption
    }
  }

  Column {
    width: parent.width
    spacing: Style.spaceTight
    visible: root.type === "choice"

    Repeater {
      model: root.type === "choice" ? (root.field.options || []) : []

      ListRow {
        required property var modelData
        label: modelData.label ? modelData.label : modelData.value
        active: String(root.value) === String(modelData.value)
        onClicked: root.edited(modelData.value)
      }
    }
  }

  Text {
    width: parent.width
    wrapMode: Text.WordWrap
    visible: ["text", "bool", "number", "choice"].indexOf(root.type) === -1
    text: "Field type " + root.type + " has no editor yet."
    color: Theme.warning
    font.family: Style.fontFamily
    font.pixelSize: Style.fontMicro
  }

  Text {
    width: parent.width
    wrapMode: Text.WordWrap
    visible: !!root.field.hint
    text: root.field.hint ? root.field.hint : ""
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontMicro
  }
}
