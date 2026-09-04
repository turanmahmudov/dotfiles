import QtQuick
import qs.Ui

Item {
  id: overlayRoot

  OsdToast {
    id: osd

    Component.onCompleted: {
      Brightness.value
      NightLight.enabled
    }

    Connections {
      target: Brightness
      function onValueChanged() {
        osd.show("sun", Brightness.value / 100)
      }
      function onKbdLevelChanged() {
        osd.show("keyboard", Brightness.kbdLevel)
      }
    }
  }

  ModePicker {}
}
