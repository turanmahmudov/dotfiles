import QtQuick
import qs.Ui

SliderRow {
  id: root

  property var controller: null
  property string pluginId: ""
  property bool shown: Brightness.available

  iconName: "sun"
  hasDetail: true
  value: Brightness.value / 100
  onMoved: (v) => Brightness.setPercent(Math.round(v * 100))
  onDetailRequested: if (root.controller) root.controller.go(root.pluginId)
}
