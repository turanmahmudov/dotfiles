import QtQuick
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "Graphics mode"

  Column {
    width: parent.width
    spacing: Style.spaceTight

    Repeater {
      model: Prime.modes

      delegate: ListRow {
        required property var modelData
        readonly property bool pending: Prime.pendingMode === modelData && Prime.mode !== modelData
        iconName: Prime.resolveIcon(modelData)
        label: Prime.resolveLabel(modelData)
        active: Prime.mode === modelData
        value: pending ? "after logout" : ""
        valueColor: Theme.warning
        onClicked: Prime.selectMode(modelData)
      }
    }
  }
}
