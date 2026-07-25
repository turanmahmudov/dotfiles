import QtQuick
import qs.Commons
import qs.Ui

BarItem {
  id: root

  tooltipText: "Volume " + Math.round(Audio.volume * 100) + "%" + (Audio.muted ? " (muted)" : "") + "  ·  Mic " + (Audio.micMuted ? "muted" : "on")
  onClicked: openPanel()
  onRightClicked: Audio.toggleMute()
  onScrolledUp: Audio.changeVolume(0.05)
  onScrolledDown: Audio.changeVolume(-0.05)

  Icon {
    name: Icons.volume(Audio.muted, Audio.volume)
    color: (Audio.muted || root.hovered) ? Theme.fgDim : Theme.fg
  }
}
