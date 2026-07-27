import QtQuick
import qs.Commons
import qs.Ui

SliderRow {
  id: root

  property var controller: null
  property string pluginId: ""

  iconName: Icons.volume(Audio.muted, Audio.volume)
  iconIsButton: true
  hasDetail: true
  value: Audio.volume
  onMoved: (v) => Audio.setVolume(v)
  onIconClicked: Audio.toggleMute()
  onDetailRequested: if (root.controller) root.controller.go(root.pluginId)
}
