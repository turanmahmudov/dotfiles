import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  readonly property real step: (settings && Number(settings.step) > 0) ? Number(settings.step) : 0.05

  tooltipText: "Volume " + Math.round(Audio.volume * 100) + "%" + (Audio.muted ? " (muted)" : "") + "  ·  Mic " + (Audio.micMuted ? "muted" : "on")
  onClicked: openPanel()
  onRightClicked: Audio.toggleMute()
  onScrolledUp: Audio.changeVolume(root.step)
  onScrolledDown: Audio.changeVolume(-root.step)

  Icon {
    name: Icons.volume(Audio.muted, Audio.volume)
    color: (Audio.muted || root.hovered) ? Theme.fgDim : Theme.fg
  }
}
