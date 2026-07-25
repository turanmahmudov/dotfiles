import QtQuick
import qs.Commons
import qs.Ui

OsdToast {
  id: osd

  Component.onCompleted: Audio.volume

  Connections {
    target: Audio
    function onVolumeChanged() {
      osd.show(Icons.volume(Audio.muted, Audio.volume), Audio.volume)
    }
    function onMutedChanged() {
      osd.show(Icons.volume(Audio.muted, Audio.volume), Audio.volume)
    }
    function onMicMutedChanged() {
      osd.show(Audio.micMuted ? "mic-off" : "mic", Audio.micVolume)
    }
  }
}
