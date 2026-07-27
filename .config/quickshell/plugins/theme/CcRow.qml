import QtQuick
import qs.Ui

InfoRow {
  id: root

  property var controller: null
  property string pluginId: ""

  iconName: "palette"
  label: "Appearance"
  sublabel: "Theme and wallpaper"
  value: Themes.displayName.length > 0 ? (Themes.displayName + "  ·  " + Themes.mode) : "Theme"
  onClicked: if (root.controller) root.controller.go(root.pluginId)
}
