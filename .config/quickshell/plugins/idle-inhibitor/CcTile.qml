import QtQuick
import qs.Ui

Tile {
  iconName: KeepAwake.active ? "eye" : "eye-off"
  label: "Keep awake"
  sublabel: KeepAwake.active ? "On" : "Off"
  active: KeepAwake.active
  onTriggered: KeepAwake.toggle()
}
